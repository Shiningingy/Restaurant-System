// Moneris API (the new REST API at api.moneris.io) server-to-server calls — the
// ONLY place the Moneris wire format lives. Card data never reaches here: the
// customer enters it in Moneris's Hosted Tokenization iframe, which returns a
// temporary token; we charge that token via /payments.
//
// Auth is EITHER the Subscriptions API key (X-Api-Key) OR OAuth2
// client-credentials (Payment + Refund scopes). The API key is set on a key
// whose Subscription includes the Payments/Refunds APIs; OAuth2 carries the
// scopes explicitly (but its secret expires). If MONERIS_API_KEY is set we use
// it, else we fall back to OAuth2. ⚠️ Validate request/response field names
// against the QA sandbox (api.sb.moneris.io) — see developer.moneris.com/moneris-api.

export interface MonerisConfig {
  apiKey: string; // Subscriptions API key -> X-Api-Key (preferred if set)
  clientId: string; // OAuth2 client-credentials (fallback)
  clientSecret: string;
  merchantId: string; // 13-char -> X-Merchant-Id
  htProfileId: string; // Hosted Tokenization profile id (the iframe)
  env: "qa" | "prod";
  apiVersion: string; // e.g. "2025-08-14"
}

function apiHost(env: string): string {
  return env === "prod" ? "https://api.moneris.io" : "https://api.sb.moneris.io";
}

/// Hosted Tokenization iframe host (the card-entry frame).
function htHost(env: string): string {
  return env === "prod"
    ? "https://www3.moneris.com"
    : "https://esqa.moneris.com";
}

/// The iframe src that renders Moneris's hosted card field for this profile.
export function htIframeSrc(cfg: MonerisConfig): string {
  return `${htHost(cfg.env)}/HPPtoken/index.php` +
    `?id=${encodeURIComponent(cfg.htProfileId)}&pmmsg=true`;
}

/// The origin the iframe posts its result from (for postMessage checks).
export function htOrigin(cfg: MonerisConfig): string {
  return htHost(cfg.env);
}

/// The auth header: the API key when present, else an OAuth2 bearer obtained
/// via client-credentials (scopes payment/refund). A fresh token per call keeps
/// the function stateless; tokens are good for ~1h so this is cheap at our rate.
async function authHeader(cfg: MonerisConfig): Promise<Record<string, string>> {
  if (cfg.apiKey) return { "X-Api-Key": cfg.apiKey };
  const resp = await fetch(`${apiHost(cfg.env)}/oauth2/token`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "client_credentials",
      client_id: cfg.clientId,
      client_secret: cfg.clientSecret,
      scope: "payment.write payment.read refund.write refund.read",
    }),
  });
  const j = await resp.json().catch(() => ({}));
  if (!resp.ok || !j.access_token) {
    throw new Error(`oauth token failed: ${resp.status} ${JSON.stringify(j)}`);
  }
  return { Authorization: `Bearer ${j.access_token}` };
}

async function headers(
  cfg: MonerisConfig,
  idempotencyKey: string,
): Promise<Record<string, string>> {
  return {
    ...await authHeader(cfg),
    "X-Merchant-Id": cfg.merchantId,
    "Api-Version": cfg.apiVersion,
    "Idempotency-Key": idempotencyKey,
    "Content-Type": "application/json",
  };
}

export interface PurchaseResult {
  approved: boolean;
  paymentId: string | null;
  amountCents: number | null;
  raw: unknown;
}

/// Charges a Hosted-Tokenization temporary token. Amount is in minor units
/// (cents). [idempotencyKey] makes a retried verify safe (no double charge).
export async function purchaseWithToken(
  cfg: MonerisConfig,
  args: {
    token: string;
    amountCents: number;
    orderId: string;
    idempotencyKey: string;
  },
): Promise<PurchaseResult> {
  const resp = await fetch(`${apiHost(cfg.env)}/payments`, {
    method: "POST",
    headers: await headers(cfg, args.idempotencyKey),
    body: JSON.stringify({
      idempotencyKey: args.idempotencyKey,
      orderId: args.orderId,
      amount: { amount: args.amountCents, currency: "CAD" },
      paymentMethod: {
        paymentMethodSource: "TEMPORARY_TOKEN",
        temporaryToken: args.token,
        storePaymentMethod: "DO_NOT_STORE",
      },
    }),
  });
  const json = await resp.json().catch(() => ({})) as Record<string, unknown>;
  const status = `${json.paymentStatus ?? ""}`.toUpperCase();
  const amt = (json.amount as Record<string, unknown>)?.amount;
  return {
    approved: resp.ok && status === "SUCCEEDED",
    paymentId: (json.paymentId as string) ?? null,
    amountCents: typeof amt === "number" ? amt : null,
    raw: json,
  };
}

/// Refunds a completed payment by its [paymentId] (a "matching refund").
export async function refundPayment(
  cfg: MonerisConfig,
  args: { paymentId: string; amountCents: number; idempotencyKey: string },
): Promise<{ success: boolean; raw: unknown }> {
  const resp = await fetch(`${apiHost(cfg.env)}/refunds`, {
    method: "POST",
    headers: await headers(cfg, args.idempotencyKey),
    body: JSON.stringify({
      idempotencyKey: args.idempotencyKey,
      paymentId: args.paymentId,
      refundAmount: { amount: args.amountCents, currency: "CAD" },
    }),
  });
  const json = await resp.json().catch(() => ({})) as Record<string, unknown>;
  const status = `${json.refundStatus ?? ""}`.toUpperCase();
  return { success: resp.ok && status === "SUCCEEDED", raw: json };
}
