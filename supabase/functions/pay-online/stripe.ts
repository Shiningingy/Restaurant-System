// Stripe **PaymentIntents + Payment Element** server-to-server calls — the ONLY
// place the Stripe wire format lives. Card data never reaches here: the customer
// types it into Stripe's Payment Element (an iframe served by js.stripe.com), the
// card goes straight to Stripe, and we only ever see a PaymentIntent id + status.
//
// Flow (same shape as the Moneris/Helcim siblings, different vendor):
//   1. create    - POST /v1/payment_intents with the amount we computed from the
//      order -> { id, client_secret }. The amount is FIXED here, server-side, so
//      the customer cannot alter what they pay.
//   2. render    - the browser loads Stripe.js, mounts the Payment Element with
//      the client_secret, and confirms. Stripe charges the card directly.
//   3. verify    - we RETRIEVE the PaymentIntent server-to-server and require
//      status === "succeeded" + the right amount/currency before writing paid.
//      Retrieval is what makes the customer's "it worked" claim untrustworthy on
//      its own — the truth comes from Stripe, not from the browser.
//
// Note this needs no per-order server-side secret (unlike Helcim's secretToken
// hash), because verification is a stateless authenticated GET by PaymentIntent
// id — so a Stripe deployment needs no extra `online_orders` column.
//
// Auth is a single secret key (`Authorization: Bearer sk_...`). The Stripe API is
// FORM-ENCODED (not JSON), and amounts are INTEGER MINOR UNITS (cents) — which
// matches our Money type exactly, unlike Helcim's decimal dollars.

export interface StripeConfig {
  secretKey: string; // sk_test_… / sk_live_… -> Authorization: Bearer
  publishableKey: string; // pk_test_… / pk_live_… -> used by the browser page
  currency: string; // lowercase ISO, e.g. "cad"
}

const STRIPE_API = "https://api.stripe.com/v1";

/// The Stripe.js loader the checkout page must include.
export const STRIPE_JS = "https://js.stripe.com/v3/";

/// Masks a secret for safe echoing in diagnostics: length + last 4 chars only.
function mask(s: string): string {
  if (!s) return "(unset)";
  return `len=${s.length} ...${s.slice(-4)}`;
}

function authHeaders(
  cfg: StripeConfig,
  idempotencyKey?: string,
): Record<string, string> {
  const h: Record<string, string> = {
    Authorization: `Bearer ${cfg.secretKey}`,
    "Content-Type": "application/x-www-form-urlencoded",
  };
  if (idempotencyKey) h["Idempotency-Key"] = idempotencyKey;
  return h;
}

export interface IntentResult {
  id: string; // pi_…
  clientSecret: string; // pi_…_secret_… (safe for the browser)
}

/// Creates (or, on a retried GET with the same idempotency key, returns) a
/// PaymentIntent for a FIXED amount. Re-serving the checkout page for the same
/// order therefore reuses ONE PaymentIntent rather than littering the dashboard —
/// and a declined card can simply be retried against it.
/// Throws with the raw body on failure so a bad key is diagnosable.
export async function createPaymentIntent(
  cfg: StripeConfig,
  args: { amountCents: number; orderId: string; idempotencyKey: string },
): Promise<IntentResult> {
  const body = new URLSearchParams({
    amount: String(args.amountCents),
    currency: cfg.currency,
    // Let Stripe decide which methods to show (cards, and wallets where the
    // device supports them) instead of hard-coding a list.
    "automatic_payment_methods[enabled]": "true",
    // Ties the Stripe payment back to our order in the Stripe dashboard.
    "metadata[order_id]": args.orderId,
    description: `Order ${args.orderId}`,
  });
  const resp = await fetch(`${STRIPE_API}/payment_intents`, {
    method: "POST",
    headers: authHeaders(cfg, args.idempotencyKey),
    body,
  });
  const text = await resp.text();
  let j: Record<string, unknown> = {};
  try {
    j = JSON.parse(text);
  } catch { /* non-JSON error body - keep the raw text in the thrown message */ }
  const id = j.id as string | undefined;
  const clientSecret = j.client_secret as string | undefined;
  if (!resp.ok || !id || !clientSecret) {
    throw new Error(`stripe create intent failed: ${resp.status} ${text}`);
  }
  return { id, clientSecret };
}

export interface SessionResult {
  id: string; // cs_…
  url: string; // https://checkout.stripe.com/… — redirect the customer here
}

/// Creates a Stripe-HOSTED Checkout Session for a FIXED amount and returns the
/// URL to send the customer to. This is the "build nothing" path: Stripe serves
/// the entire payment page (card fields, 3-D Secure, wallets, localization), so
/// we render no HTML and host no card UI at all.
///
/// It also sidesteps a Supabase quirk: Edge Function responses are served as
/// `text/plain`, so OUR html needs a webview that can relabel it — whereas a 302
/// to Stripe is served by Stripe as real HTML, which any plain webview renders.
export async function createCheckoutSession(
  cfg: StripeConfig,
  args: {
    amountCents: number;
    orderId: string;
    successUrl: string;
    cancelUrl: string;
    idempotencyKey: string;
    /// What the customer sees as the line item. A raw uuid is meaningless to
    /// someone who was just texted a link, so pay-by-link passes something
    /// human ("Yee Sushi — takeout order").
    label?: string;
  },
): Promise<SessionResult> {
  const body = new URLSearchParams({
    mode: "payment",
    success_url: args.successUrl,
    cancel_url: args.cancelUrl,
    client_reference_id: args.orderId,
    "metadata[order_id]": args.orderId,
    "line_items[0][quantity]": "1",
    "line_items[0][price_data][currency]": cfg.currency,
    "line_items[0][price_data][unit_amount]": String(args.amountCents),
    "line_items[0][price_data][product_data][name]": args.label?.trim().length
      ? args.label!.trim()
      : `Order ${args.orderId}`,
    // Carry the order id onto the PaymentIntent too, so a refund or a dashboard
    // lookup can be traced back without going via the session.
    "payment_intent_data[metadata][order_id]": args.orderId,
  });
  const resp = await fetch(`${STRIPE_API}/checkout/sessions`, {
    method: "POST",
    headers: authHeaders(cfg, args.idempotencyKey),
    body,
  });
  const text = await resp.text();
  let j: Record<string, unknown> = {};
  try {
    j = JSON.parse(text);
  } catch { /* non-JSON error body - keep the raw text in the thrown message */ }
  const id = j.id as string | undefined;
  const url = j.url as string | undefined;
  if (!resp.ok || !id || !url) {
    throw new Error(`stripe create session failed: ${resp.status} ${text}`);
  }
  return { id, url };
}

export interface SessionStatus {
  id: string;
  paymentStatus: string; // "paid" when settled
  /// The session's own lifecycle: "open" | "complete" | "expired". Needed to
  /// tell "still waiting" apart from "this link will never be paid" — an
  /// expired session is unpaid but dead, and staff need to know the difference.
  sessionStatus: string;
  amountTotalCents: number | null;
  currency: string | null;
  paymentIntentId: string | null; // for refunds
  raw: unknown;
}

/// Reads a Checkout Session back from Stripe. Like retrievePaymentIntent, this is
/// the trust anchor: the customer's browser returning to our success_url proves
/// nothing on its own, so we ask Stripe whether it was actually paid.
export async function retrieveCheckoutSession(
  cfg: StripeConfig,
  sessionId: string,
): Promise<SessionStatus> {
  const resp = await fetch(
    `${STRIPE_API}/checkout/sessions/${encodeURIComponent(sessionId)}`,
    { headers: { Authorization: `Bearer ${cfg.secretKey}` } },
  );
  const text = await resp.text();
  let j: Record<string, unknown> = {};
  try {
    j = JSON.parse(text);
  } catch { /* keep raw text */ }
  const pi = j.payment_intent;
  return {
    id: (j.id as string) ?? sessionId,
    paymentStatus: `${j.payment_status ?? ""}`,
    sessionStatus: `${j.status ?? ""}`,
    amountTotalCents: typeof j.amount_total === "number" ? j.amount_total : null,
    currency: (j.currency as string) ?? null,
    // Expands to an object when requested; a bare string otherwise.
    paymentIntentId: typeof pi === "string"
      ? pi
      : ((pi as Record<string, unknown>)?.id as string) ?? null,
    raw: j.id ? j : text,
  };
}

export interface IntentStatus {
  id: string;
  status: string; // "succeeded" when paid
  amountCents: number | null;
  amountReceivedCents: number | null;
  currency: string | null;
  httpStatus: number;
  raw: unknown;
}

/// Reads a PaymentIntent back from Stripe. This is the trust anchor: the browser
/// tells us an id, Stripe tells us whether it actually succeeded and for how much.
export async function retrievePaymentIntent(
  cfg: StripeConfig,
  paymentIntentId: string,
): Promise<IntentStatus> {
  const resp = await fetch(
    `${STRIPE_API}/payment_intents/${encodeURIComponent(paymentIntentId)}`,
    { headers: { Authorization: `Bearer ${cfg.secretKey}` } },
  );
  const text = await resp.text();
  let j: Record<string, unknown> = {};
  try {
    j = JSON.parse(text);
  } catch { /* keep raw text */ }
  const num = (v: unknown) => (typeof v === "number" ? v : null);
  return {
    id: (j.id as string) ?? paymentIntentId,
    status: `${j.status ?? ""}`,
    amountCents: num(j.amount),
    amountReceivedCents: num(j.amount_received),
    currency: (j.currency as string) ?? null,
    httpStatus: resp.status,
    raw: j.id ? j : text,
  };
}

export interface RefundResult {
  success: boolean;
  raw: unknown;
}

/// Refunds a completed payment by its PaymentIntent id. Amount is in cents.
/// The `Idempotency-Key` makes a retried refund safe (no double refund).
export async function refundPayment(
  cfg: StripeConfig,
  args: {
    paymentIntentId: string;
    /// Omit to refund the FULL captured charge — which is what you want when
    /// reconciliation failed and you don't trust your own expected amount.
    amountCents?: number;
    idempotencyKey: string;
  },
): Promise<RefundResult> {
  const body = new URLSearchParams({ payment_intent: args.paymentIntentId });
  if (args.amountCents != null) {
    body.set("amount", String(args.amountCents));
  }
  const resp = await fetch(`${STRIPE_API}/refunds`, {
    method: "POST",
    headers: authHeaders(cfg, args.idempotencyKey),
    body,
  });
  const text = await resp.text();
  let j: Record<string, unknown> = {};
  try {
    j = JSON.parse(text);
  } catch { /* keep raw text */ }
  const status = `${j.status ?? ""}`;
  return {
    // Stripe returns "succeeded" immediately for card refunds, or "pending" for
    // methods that settle asynchronously — both mean the refund was accepted.
    success: resp.ok && (status === "succeeded" || status === "pending"),
    raw: j.id ? j : text,
  };
}

/// DEBUG: confirms the secret key works by creating (and immediately cancelling)
/// a $1 PaymentIntent. Returns the masked key + the outcome so a bad credential
/// surfaces in full instead of a blank 500.
export async function diagnose(cfg: StripeConfig): Promise<unknown> {
  const out: Record<string, unknown> = {
    api: STRIPE_API,
    secretKey: mask(cfg.secretKey),
    publishableKey: mask(cfg.publishableKey),
    currency: cfg.currency,
    // A live key here while you are still testing is the single most expensive
    // mistake available, so make the mode impossible to miss.
    mode: cfg.secretKey.startsWith("sk_live_")
      ? "LIVE — real money"
      : cfg.secretKey.startsWith("sk_test_")
      ? "test"
      : "unknown",
  };
  try {
    const r = await createPaymentIntent(cfg, {
      amountCents: 100,
      orderId: "diag",
      // Vary per call so the diagnostic never replays a cached intent.
      idempotencyKey: `diag${crypto.randomUUID().replaceAll("-", "")}`.slice(
        0,
        36,
      ),
    });
    out.createIntentOk = true;
    out.paymentIntentId = `...${r.id.slice(-6)}`;
    // Tidy up so diagnostics don't leave open intents lying around.
    await fetch(
      `${STRIPE_API}/payment_intents/${encodeURIComponent(r.id)}/cancel`,
      { method: "POST", headers: authHeaders(cfg) },
    ).catch(() => {});
  } catch (e) {
    out.createIntentOk = false;
    out.error = e instanceof Error ? e.message : String(e);
  }
  return out;
}
