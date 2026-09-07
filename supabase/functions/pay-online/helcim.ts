// Helcim **HelcimPay.js** server-to-server calls — the ONLY place the Helcim wire
// format lives. Card data never reaches here: the customer enters it in Helcim's
// hosted payment modal (rendered by HelcimPay.js from a `checkoutToken` we mint),
// which processes the charge and returns a signed result. We only ever see a
// transaction id, an amount, and a hash we validate.
//
// Flow (mirrors the Moneris hosted-tokenization shape, different vendor):
//   1. initialize  - POST /v2/helcim-pay/initialize with the amount we computed
//      from the order -> { checkoutToken, secretToken }. The amount is FIXED here,
//      server-side, so the customer can't alter what they pay.
//   2. render       - the browser loads HelcimPay.js and calls
//      appendHelcimPayIframe(checkoutToken); the customer pays in the modal.
//   3. validate     - on the SUCCESS event the modal returns { data, hash };
//      we recompute sha256(compactJson(data) + secretToken) and compare, which
//      proves the result genuinely came from Helcim (the customer can't forge an
//      "approved" without the secretToken). Then we trust data.status/amount.
//
// Auth is a single Helcim API token (`api-token` header). Amounts on the Helcim
// API are DECIMAL DOLLARS (e.g. 15.81), NOT minor units - unlike Moneris.

export interface HelcimConfig {
  apiToken: string; // Helcim API token -> `api-token` header
  currency: string; // e.g. "CAD"
}

const HELCIM_API = "https://api.helcim.com/v2";

/// The HelcimPay.js loader the checkout page must include.
export const HELCIM_PAY_SCRIPT =
  "https://secure.helcim.app/helcim-pay/services/start.js";

/// Cents -> the decimal-dollar Number the Helcim API expects (2 dp).
function dollars(cents: number): number {
  return Number((cents / 100).toFixed(2));
}

/// Masks a secret for safe echoing in diagnostics: length + last 4 chars only.
function mask(s: string): string {
  if (!s) return "(unset)";
  return `len=${s.length} ...${s.slice(-4)}`;
}

export interface InitResult {
  checkoutToken: string;
  secretToken: string;
}

/// Mints a HelcimPay.js checkout session for a FIXED amount. The returned
/// checkoutToken renders the modal; the secretToken must be kept server-side to
/// validate the result later (we stash it on the order row between GET and POST).
/// Throws with the raw body on failure so a bad token/credential is diagnosable.
export async function initializeCheckout(
  cfg: HelcimConfig,
  args: { amountCents: number; orderId: string },
): Promise<InitResult> {
  const resp = await fetch(`${HELCIM_API}/helcim-pay/initialize`, {
    method: "POST",
    headers: {
      "api-token": cfg.apiToken,
      "accept": "application/json",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      paymentType: "purchase",
      amount: dollars(args.amountCents),
      currency: cfg.currency,
      language: "en",
      // Ties the Helcim transaction back to our order in Helcim's dashboard.
      invoiceNumber: args.orderId,
    }),
  });
  const text = await resp.text();
  let j: Record<string, unknown> = {};
  try {
    j = JSON.parse(text);
  } catch { /* non-JSON error body - keep the raw text in the thrown message */ }
  const checkoutToken = j.checkoutToken as string | undefined;
  const secretToken = j.secretToken as string | undefined;
  if (!resp.ok || !checkoutToken || !secretToken) {
    throw new Error(`helcim initialize failed: ${resp.status} ${text}`);
  }
  return { checkoutToken, secretToken };
}

/// Escapes non-ASCII to \uXXXX so our compact JSON matches Helcim's hash input.
/// Helcim hashes "the JSON-escaped unicode representation of special characters"
/// (Python json.dumps ensure_ascii=True), while JS JSON.stringify emits raw
/// UTF-8 - so an accented cardholder name would mismatch without this.
function escapeNonAscii(s: string): string {
  let out = "";
  for (let i = 0; i < s.length; i++) {
    const code = s.charCodeAt(i);
    out += code > 127
      ? "\\u" + code.toString(16).padStart(4, "0")
      : s[i];
  }
  return out;
}

async function sha256Hex(input: string): Promise<string> {
  const bytes = new TextEncoder().encode(input);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/// Validates the HelcimPay.js SUCCESS payload: recompute the hash over the
/// transaction `data` object + secretToken and compare to the returned `hash`.
/// A match proves the result is genuinely from Helcim and untampered.
export async function validatePaymentHash(
  secretToken: string,
  data: Record<string, unknown>,
  hash: string,
): Promise<boolean> {
  // Normalize exactly like Helcim: re-encode compact (no spaces), ASCII-escaped.
  const compact = escapeNonAscii(JSON.stringify(data));
  const computed = await sha256Hex(compact + secretToken);
  // Length-checked constant-ish comparison.
  if (computed.length !== hash.length) return false;
  let diff = 0;
  for (let i = 0; i < computed.length; i++) {
    diff |= computed.charCodeAt(i) ^ hash.charCodeAt(i);
  }
  return diff === 0;
}

export interface RefundResult {
  success: boolean;
  raw: unknown;
}

/// Refunds a completed HelcimPay purchase by its original transaction id. Amount
/// is in cents (converted to dollars for Helcim). The Payment API requires an
/// `idempotency-key` so a retried refund can't double-refund.
///
/// NOTE: verify this exact wire shape against a Helcim sandbox before going live
/// - Helcim documents both a card-token refund (`/payment/refund`) and a
/// device/terminal refund; this uses the online `/payment/refund` variant.
export async function refundPayment(
  cfg: HelcimConfig,
  args: {
    originalTransactionId: string;
    amountCents: number;
    idempotencyKey: string;
  },
): Promise<RefundResult> {
  const resp = await fetch(`${HELCIM_API}/payment/refund`, {
    method: "POST",
    headers: {
      "api-token": cfg.apiToken,
      "idempotency-key": args.idempotencyKey,
      "accept": "application/json",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      originalTransactionId: args.originalTransactionId,
      amount: dollars(args.amountCents),
      currency: cfg.currency,
    }),
  });
  const text = await resp.text();
  let j: Record<string, unknown> = {};
  try {
    j = JSON.parse(text);
  } catch { /* keep raw text */ }
  const status = `${j.status ?? ""}`.toUpperCase();
  return {
    // Helcim returns 200/201 with status APPROVED, or 202 Accepted on the async
    // path - treat any 2xx with a non-declined status as success; raw carries the
    // full body for diagnosis.
    success: resp.ok && status !== "DECLINED",
    raw: j.status ? j : text,
  };
}

/// DEBUG: confirms the API token works by minting (and discarding) a $1 checkout
/// session. Returns the masked token + the initialize outcome so a bad credential
/// surfaces in full instead of a blank 500.
export async function diagnose(cfg: HelcimConfig): Promise<unknown> {
  const out: Record<string, unknown> = {
    api: HELCIM_API,
    apiToken: mask(cfg.apiToken),
    currency: cfg.currency,
  };
  try {
    const r = await initializeCheckout(cfg, {
      amountCents: 100,
      orderId: "diag",
    });
    out.initializeOk = true;
    out.checkoutToken = `...${r.checkoutToken.slice(-6)}`;
  } catch (e) {
    out.initializeOk = false;
    out.error = e instanceof Error ? e.message : String(e);
  }
  return out;
}
