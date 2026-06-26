// Moneris Checkout (MCO) server-to-server calls — the ONLY place the Moneris
// wire format lives. The restaurant's secret store credentials are passed in;
// they never leave the Edge Function.
//
// ⚠️ Field names / response paths follow the Moneris Checkout Integration Guide
// (Moneris-Checkout-IG) and the classic Gateway API. They are isolated here so
// they can be confirmed against the QA sandbox without touching the rest of the
// function. Validate end-to-end against gatewayt.moneris.com before going live.

export interface MonerisConfig {
  storeId: string;
  apiToken: string;
  checkoutId: string;
  env: "qa" | "prod";
}

/// Moneris Checkout host (preload + receipt).
function checkoutHost(env: string): string {
  return env === "prod"
    ? "https://gateway.moneris.com"
    : "https://gatewayt.moneris.com";
}

/// Classic MPG Gateway host (used for refunds/voids of a completed txn).
function gatewayHost(env: string): string {
  return env === "prod"
    ? "https://www3.moneris.com"
    : "https://esqa.moneris.com";
}

/// The Moneris Checkout JS library the hosted page loads.
export function checkoutJsUrl(env: string): string {
  return `${checkoutHost(env)}/chkt/js/chkt_v1.00.js`;
}

/// The mode string the JS library expects (`setMode`).
export function checkoutMode(env: string): string {
  return env === "prod" ? "prod" : "qa";
}

async function postCheckout(
  cfg: MonerisConfig,
  body: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const resp = await fetch(`${checkoutHost(cfg.env)}/chkt/request/request.php`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      store_id: cfg.storeId,
      api_token: cfg.apiToken,
      checkout_id: cfg.checkoutId,
      environment: cfg.env,
      ...body,
    }),
  });
  const json = await resp.json().catch(() => ({}));
  // MCO wraps everything in `response`.
  return (json.response ?? json) as Record<string, unknown>;
}

/// Preload: register the amount and get a one-time `ticket` to start checkout.
/// [txnTotal] is a decimal string ("12.34"); [orderNo] is our order id.
export async function preload(
  cfg: MonerisConfig,
  args: { txnTotal: string; orderNo: string },
): Promise<{ ticket: string }> {
  const r = await postCheckout(cfg, {
    action: "preload",
    txn_total: args.txnTotal,
    order_no: args.orderNo,
    language: "en",
  });
  const ticket = r.ticket as string | undefined;
  if (`${r.success}` !== "true" || !ticket) {
    throw new Error(`preload failed: ${JSON.stringify(r)}`);
  }
  return { ticket };
}

export interface ReceiptResult {
  approved: boolean;
  amountCents: number;
  txnRef: string | null;
  orderNo: string | null;
}

/// Receipt: after the customer pays, confirm the outcome and the amount.
/// We trust ONLY this server-to-server result, never the browser.
export async function receipt(
  cfg: MonerisConfig,
  args: { ticket: string },
): Promise<ReceiptResult> {
  const r = await postCheckout(cfg, { action: "receipt", ticket: args.ticket });
  // The receipt nests the gateway result under `receipt`; the exact shape is
  // confirmed in the IG. Parse defensively.
  const rec = (r.receipt ?? {}) as Record<string, unknown>;
  const cc = (rec.cc ?? {}) as Record<string, unknown>;
  const result = `${rec.result ?? cc.result ?? ""}`.toLowerCase();
  // Approved when the gateway returns "a" (approved) and MCO reports success.
  const approved = `${r.success}` === "true" && (result === "a" || result === "approved");
  const amount = parseFloat(`${cc.amount ?? rec.amount ?? "0"}`);
  const txnRef = (cc.reference_no ?? cc.txn_no ?? rec.reference_no ?? rec.txn_no ??
    null) as string | null;
  const orderNo = (rec.order_no ?? cc.order_no ?? null) as string | null;
  return {
    approved,
    amountCents: Math.round((isNaN(amount) ? 0 : amount) * 100),
    txnRef: txnRef ? `${txnRef}` : null,
    orderNo: orderNo ? `${orderNo}` : null,
  };
}

/// Refund a completed Moneris Checkout purchase via the classic Gateway API.
/// Needs the original order id + the processor txn number from the receipt.
export async function refund(
  cfg: MonerisConfig,
  args: { orderNo: string; txnNumber: string; amountCents: number },
): Promise<{ success: boolean; detail: string }> {
  const amount = (args.amountCents / 100).toFixed(2);
  const xml = `<?xml version="1.0"?>
<request>
  <store_id>${cfg.storeId}</store_id>
  <api_token>${cfg.apiToken}</api_token>
  <refund>
    <order_id>${escapeXml(args.orderNo)}</order_id>
    <amount>${amount}</amount>
    <txn_number>${escapeXml(args.txnNumber)}</txn_number>
    <crypt_type>7</crypt_type>
  </refund>
</request>`;
  const resp = await fetch(`${gatewayHost(cfg.env)}/gateway2/servlet/MpgRequest`, {
    method: "POST",
    headers: { "Content-Type": "application/xml" },
    body: xml,
  });
  const text = await resp.text();
  // The gateway returns XML; a refund is good when Complete=true and the
  // ResponseCode is below 50 (Moneris' approved range).
  const complete = /<Complete>\s*true\s*<\/Complete>/i.test(text);
  const codeMatch = text.match(/<ResponseCode>\s*(\d+)\s*<\/ResponseCode>/i);
  const code = codeMatch ? parseInt(codeMatch[1], 10) : 999;
  return { success: complete && code < 50, detail: text };
}

function escapeXml(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}
