// Moneris sandbox check — proves your credentials + the new-API request shapes
// without the Hosted Tokenization iframe (which needs a real store). It:
//   1. authenticates (API key, or OAuth2 client-credentials),
//   2. does a Purchase with a TEST CARD,
//   3. Refunds that payment.
//
// Run (PowerShell):
//   $env:MONERIS_ENV="qa"; $env:MONERIS_MERCHANT_ID="<13-char id>"
//   $env:MONERIS_API_KEY="<key>"              # OR the two OAuth2 vars below
//   # $env:MONERIS_CLIENT_ID="..."; $env:MONERIS_CLIENT_SECRET="..."
//   node tools/moneris-sandbox-check.mjs
//
// Needs Node 18+ (global fetch). Swap TEST_CARD for Moneris's official sandbox
// test card (from the Moneris Postman collection / docs) if 4242… is rejected.

const env = (k, d) => process.env[k] ?? d;
const ENV = env("MONERIS_ENV", "qa");
const HOST = ENV === "prod"
  ? "https://api.moneris.io"
  : "https://api.sb.moneris.io";
const MERCHANT = env("MONERIS_MERCHANT_ID");
const VERSION = env("MONERIS_API_VERSION", "2025-08-14");

// ⚠️ Replace with Moneris's published sandbox test card if this one declines.
const TEST_CARD = {
  cardNumber: "4242424242424242",
  expiryMonth: 12,
  expiryYear: 2027,
  cardSecurityCode: "123",
};

const uid = () => Math.random().toString(36).slice(2, 14);

if (!MERCHANT) {
  console.error("Set MONERIS_MERCHANT_ID");
  process.exit(1);
}

async function authHeader() {
  if (process.env.MONERIS_API_KEY) {
    console.log("auth: X-Api-Key");
    return { "X-Api-Key": process.env.MONERIS_API_KEY };
  }
  const id = env("MONERIS_CLIENT_ID"), secret = env("MONERIS_CLIENT_SECRET");
  if (!id || !secret) {
    console.error("Set MONERIS_API_KEY, or MONERIS_CLIENT_ID + MONERIS_CLIENT_SECRET");
    process.exit(1);
  }
  const r = await fetch(`${HOST}/oauth2/token`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "client_credentials",
      client_id: id,
      client_secret: secret,
      scope: "payment.write payment.read refund.write refund.read",
    }),
  });
  const j = await r.json().catch(() => ({}));
  if (!r.ok || !j.access_token) {
    console.error("OAuth token failed:", r.status, j);
    process.exit(1);
  }
  console.log("auth: OAuth2 bearer OK");
  return { Authorization: `Bearer ${j.access_token}` };
}

const headers = (auth) => ({
  ...auth,
  "X-Merchant-Id": MERCHANT,
  "Api-Version": VERSION,
  "Idempotency-Key": uid(),
  "Content-Type": "application/json",
});

async function main() {
  console.log(`host: ${HOST}  merchant: ${MERCHANT}`);
  const auth = await authHeader();

  // 1. Purchase with a test card.
  const purchase = await fetch(`${HOST}/payments`, {
    method: "POST",
    headers: headers(auth),
    body: JSON.stringify({
      idempotencyKey: uid(),
      orderId: "sbx-" + uid(),
      amount: { amount: 100, currency: "CAD" }, // $1.00
      paymentMethod: {
        paymentMethodSource: "CARD",
        card: TEST_CARD,
        cardholderInformation: { cardholderName: "Test Buyer" },
        storePaymentMethod: "DO_NOT_STORE",
      },
    }),
  });
  const pj = await purchase.json().catch(() => ({}));
  console.log("PURCHASE:", purchase.status, pj.paymentStatus, pj.paymentId);
  if (!purchase.ok || !pj.paymentId) {
    console.error("purchase failed:", JSON.stringify(pj, null, 2));
    process.exit(1);
  }

  // 2. Refund it.
  const refund = await fetch(`${HOST}/refunds`, {
    method: "POST",
    headers: headers(auth),
    body: JSON.stringify({
      idempotencyKey: uid(),
      paymentId: pj.paymentId,
      refundAmount: { amount: 100, currency: "CAD" },
    }),
  });
  const rj = await refund.json().catch(() => ({}));
  console.log("REFUND:  ", refund.status, rj.refundStatus, rj.refundId);

  console.log(
    purchase.ok && refund.ok
      ? "\n✅ Sandbox check passed — auth + purchase + refund all work."
      : "\n❌ Something failed — see the output above.",
  );
  if (!refund.ok) process.exit(1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
