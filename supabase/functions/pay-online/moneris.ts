// Moneris **new REST API** (api.moneris.io) server-to-server calls — the ONLY
// place the Moneris wire format lives. Card data never reaches here: the customer
// enters it in Moneris's Hosted Tokenization iframe, which returns a temporary
// token; we charge that token via /payments.
//
// ⚠️ THE COMBO THAT WORKS (after a long hunt):
//   • iframe  : esqa.moneris.com/HPPtoken (QA). The new-API HT host
//               mpg1t.moneris.io just 301s to esqa in the sandbox, and embedding
//               mpg1t makes the redirect 404 the profile — so embed esqa.
//   • charge  : new REST POST /payments with
//               paymentMethod.paymentMethodSource = "TEMPORARY_TOKEN".
//               The createPaymentRequest schema for Api-Version 2025-08-14 names
//               this field `paymentMethod` (the diag proved it: a paymentMethodData
//               body 400s with "Required properties are missing: paymentMethod").
//               `paymentMethodData/paymentMethodType` is a DIFFERENT api version's
//               doc — Moneris ships several side by side. Same shape as our
//               proven CARD charge (paymentMethod + paymentMethodSource).
// Auth (API key + merchant id) is confirmed VALID by the diag (authOk + a 400
// schema error, not a 401) — same Moneris account, no two-portals wall.
//
// Auth is EITHER the Subscriptions API key (X-Api-Key) OR OAuth2
// client-credentials. If MONERIS_API_KEY is set we use it, else OAuth2.

export interface MonerisConfig {
  apiKey: string; // Subscriptions API key -> X-Api-Key (preferred if set)
  clientId: string; // OAuth2 client-credentials (fallback)
  clientSecret: string;
  merchantId: string; // 13-char -> X-Merchant-Id
  htProfileId: string; // Hosted Tokenization profile id (the iframe)
  htHost: string; // HT iframe host override (else the env default)
  env: "qa" | "prod";
  apiVersion: string; // e.g. "2025-08-14"
}

function apiHost(env: string): string {
  return env === "prod" ? "https://api.moneris.io" : "https://api.sb.moneris.io";
}

/// Hosted Tokenization iframe host (the card-entry frame). In the QA sandbox
/// the new-API HT host `mpg1t.moneris.io` simply 301-redirects to
/// `esqa.moneris.com` — and pointing the iframe at mpg1t makes that redirect
/// mangle the profile URL inside the frame (Moneris' "page doesn't exist" 404).
/// So embed esqa directly (where the profile renders); the token it returns is
/// still charged on the new REST /payments. Overridable via MONERIS_HT_HOST
/// (e.g. for production, once Moneris confirms the live HT host).
function htHost(cfg: MonerisConfig): string {
  if (cfg.htHost) return cfg.htHost;
  return cfg.env === "prod"
    ? "https://www3.moneris.com"
    : "https://esqa.moneris.com";
}

/// The iframe src that renders Moneris's hosted card field for this profile.
export function htIframeSrc(cfg: MonerisConfig): string {
  return `${htHost(cfg)}/HPPtoken/index.php` +
    `?id=${encodeURIComponent(cfg.htProfileId)}&pmmsg=true`;
}

/// The origin the iframe posts its result from (for postMessage checks).
export function htOrigin(cfg: MonerisConfig): string {
  return htHost(cfg);
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
  httpStatus: number;
  raw: unknown; // the FULL response body text (so failures are diagnosable)
}

/// Masks a secret for safe echoing in diagnostics: length + last 4 chars only.
function mask(s: string): string {
  if (!s) return "(unset)";
  return `len=${s.length} …${s.slice(-4)}`;
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
  // Api-Version 2025-08-14 schema (createPaymentRequest) requires `paymentMethod`
  // with a `paymentMethodSource` discriminator — the same shape as a CARD charge:
  //   paymentMethod: { paymentMethodSource: "TEMPORARY_TOKEN", temporaryToken }
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
      },
    }),
  });
  const text = await resp.text();
  let json: Record<string, unknown> = {};
  try {
    json = JSON.parse(text);
  } catch { /* non-JSON body (e.g. an auth/HTML error) — keep the raw text */ }
  const status = `${json.paymentStatus ?? ""}`.toUpperCase();
  const amt = (json.amount as Record<string, unknown>)?.amount;
  return {
    approved: resp.ok && status === "SUCCEEDED",
    paymentId: (json.paymentId as string) ?? null,
    amountCents: typeof amt === "number" ? amt : null,
    httpStatus: resp.status,
    raw: text,
  };
}

/// DEBUG: runs the full charge path and returns EVERYTHING (auth method, masked
/// creds, the exact /payments HTTP status + headers + raw body) so a failure
/// like "invalid credentials" can be read in full. Uses [token] if given, else a
/// placeholder (an auth/credentials error surfaces regardless of token validity).
export async function diagnose(
  cfg: MonerisConfig,
  token: string | null,
): Promise<unknown> {
  const out: Record<string, unknown> = {
    env: cfg.env,
    apiHost: apiHost(cfg.env),
    htHost: htHost(cfg),
    htIframeSrc: htIframeSrc(cfg),
    authMethod: cfg.apiKey ? "X-Api-Key" : "OAuth2 client-credentials",
    apiKey: mask(cfg.apiKey),
    clientId: mask(cfg.clientId),
    clientSecret: mask(cfg.clientSecret),
    merchantId: mask(cfg.merchantId),
    htProfileId: cfg.htProfileId || "(unset)",
    apiVersion: cfg.apiVersion,
  };

  // 1. Auth: if OAuth2, the token fetch itself may be the failure point.
  let authHeaders: Record<string, string>;
  try {
    authHeaders = await authHeader(cfg);
    out.authOk = true;
  } catch (e) {
    out.authOk = false;
    out.authError = e instanceof Error ? e.message : String(e);
    return out; // can't call /payments without auth
  }

  // 2. Raw /payments call — capture status, headers, and the full body text.
  const idem = `diag${Date.now()}`;
  const resp = await fetch(`${apiHost(cfg.env)}/payments`, {
    method: "POST",
    headers: {
      ...authHeaders,
      "X-Merchant-Id": cfg.merchantId,
      "Api-Version": cfg.apiVersion,
      "Idempotency-Key": idem,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      idempotencyKey: idem,
      orderId: idem,
      amount: { amount: 100, currency: "CAD" },
      paymentMethod: {
        paymentMethodSource: "TEMPORARY_TOKEN",
        temporaryToken: token ?? "ot-DIAGNOSTIC-PLACEHOLDER",
      },
    }),
  });
  out.paymentsStatus = resp.status;
  out.paymentsHeaders = Object.fromEntries(resp.headers.entries());
  out.paymentsBody = await resp.text();
  out.tokenUsed = token ? `…${token.slice(-6)}` : "(placeholder)";
  return out;
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
