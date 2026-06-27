// Moneris **classic Gateway** (XML) server-to-server calls — the ONLY place the
// Moneris wire format lives. Card data never reaches here: the customer enters
// it in Moneris's Hosted Tokenization iframe (HPPtoken), which returns a
// temporary token (the "data key", e.g. `ot-…`); we charge that token.
//
// ⚠️ WHY THE CLASSIC GATEWAY (not the new REST API at api.moneris.io):
// Hosted Tokenization (the `HPPtoken/index.php` iframe) is a CLASSIC-Gateway
// product, and its temporary token is charged with the classic `res_purchase_cc`
// transaction (data_key) — NOT the new REST `/payments` endpoint. Feeding an HT
// token to the new API's `TEMPORARY_TOKEN` source returns a blank 500 (that
// source expects the new API's own tokenizer, a different token). A raw card on
// `/payments` works, which is exactly why a card succeeded while the HT token
// 500'd. Reference: Moneris/Gateway-HostedSolutions demo (res_purchase_cc +
// data_key over https://esqa.moneris.com/gateway2/servlet/MpgRequest).
//
// Auth is the classic **store_id + api_token** for the SAME store that owns the
// HT profile. Charge = `res_purchase_cc`; refund = `refund`. Amounts are decimal
// dollars ("50.00"); the response is a flat XML `<receipt>`.

export interface MonerisConfig {
  storeId: string; // classic Gateway store_id (the HT profile's store)
  apiToken: string; // classic Gateway api_token (same store)
  htProfileId: string; // Hosted Tokenization profile id (the iframe)
  env: "qa" | "prod";
  cryptType: string; // res_purchase_cc/refund crypt_type (default "7")
}

/// The classic Gateway endpoint (XML over HTTPS).
function gatewayUrl(env: string): string {
  const host = env === "prod"
    ? "https://www3.moneris.com"
    : "https://esqa.moneris.com";
  return `${host}/gateway2/servlet/MpgRequest`;
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

// --- XML helpers (Moneris receipts are flat, so regex extraction is enough) ---

function xmlEscape(s: string): string {
  return s
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}

/// First `<name>…</name>` value in [xml], trimmed, or null.
function tag(xml: string, name: string): string | null {
  const m = xml.match(new RegExp(`<${name}>([\\s\\S]*?)</${name}>`, "i"));
  return m ? m[1].trim() : null;
}

/// Moneris approves on a numeric ResponseCode 0–49 (50+ = declined; absent/
/// "null" = a transaction error).
function approvedCode(code: string | null): boolean {
  return code != null && /^\d+$/.test(code) && Number(code) < 50;
}

async function postXml(cfg: MonerisConfig, body: string): Promise<string> {
  const resp = await fetch(gatewayUrl(cfg.env), {
    method: "POST",
    headers: { "Content-Type": "text/xml; charset=utf-8" },
    body,
  });
  const text = await resp.text();
  if (!resp.ok && !text.includes("<receipt>")) {
    throw new Error(`gateway HTTP ${resp.status}: ${text.slice(0, 300)}`);
  }
  return text;
}

export interface PurchaseResult {
  approved: boolean;
  paymentId: string | null; // classic txn_number, for a later refund
  amountCents: number | null;
  message: string | null; // Moneris Message (approval/decline text)
  raw: unknown;
}

/// Charges a Hosted-Tokenization temporary token via the classic Gateway's
/// `res_purchase_cc` (the token rides in `<data_key>`). [orderId] doubles as
/// Moneris's idempotency key — the Gateway rejects a duplicate order_id, so a
/// retried verify can't double-charge.
export async function purchaseWithToken(
  cfg: MonerisConfig,
  args: { token: string; amountCents: number; orderId: string },
): Promise<PurchaseResult> {
  const amount = (args.amountCents / 100).toFixed(2);
  const body = `<?xml version="1.0"?>
<request>
<store_id>${xmlEscape(cfg.storeId)}</store_id>
<api_token>${xmlEscape(cfg.apiToken)}</api_token>
<res_purchase_cc>
<data_key>${xmlEscape(args.token)}</data_key>
<order_id>${xmlEscape(args.orderId)}</order_id>
<amount>${amount}</amount>
<crypt_type>${xmlEscape(cfg.cryptType)}</crypt_type>
</res_purchase_cc>
</request>`;
  const text = await postXml(cfg, body);
  const transAmount = tag(text, "TransAmount");
  return {
    approved: approvedCode(tag(text, "ResponseCode")),
    // Moneris' follow-on transactions key off the txn number (getTxnNumber()).
    paymentId: tag(text, "TransID") ?? tag(text, "ReferenceNum"),
    amountCents: transAmount != null
      ? Math.round(Number(transAmount) * 100)
      : null,
    message: tag(text, "Message"),
    raw: text,
  };
}

/// Refunds a completed purchase via the classic Gateway's `refund` — matched to
/// the original by its [orderId] + [txnNumber] (the purchase's `paymentId`).
export async function refundPayment(
  cfg: MonerisConfig,
  args: { orderId: string; txnNumber: string; amountCents: number },
): Promise<{ success: boolean; raw: unknown }> {
  const amount = (args.amountCents / 100).toFixed(2);
  const body = `<?xml version="1.0"?>
<request>
<store_id>${xmlEscape(cfg.storeId)}</store_id>
<api_token>${xmlEscape(cfg.apiToken)}</api_token>
<refund>
<order_id>${xmlEscape(args.orderId)}</order_id>
<amount>${amount}</amount>
<txn_number>${xmlEscape(args.txnNumber)}</txn_number>
<crypt_type>${xmlEscape(cfg.cryptType)}</crypt_type>
</refund>
</request>`;
  const text = await postXml(cfg, body);
  return { success: approvedCode(tag(text, "ResponseCode")), raw: text };
}
