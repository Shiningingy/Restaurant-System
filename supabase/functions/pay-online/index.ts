// Supabase Edge Function: pay-online
//
// The trusted backend for online card payment (Phase 7). The restaurant deploys
// this on its OWN Supabase project with its OWN Moneris credentials — we host
// nothing and never hold a key. Card data goes customer → Moneris's Hosted
// Tokenization iframe directly; this function only ever sees a temporary token,
// a paymentId, and a result.
//
// It is the ONLY writer of online_orders.payment_status = 'paid': it charges the
// token server-to-server and recomputes the amount from the order (so nobody
// pays $0.01 for a $50 order) before trusting it.
//
// Deploy WITHOUT JWT verification (the customer's browser opens the GET with no
// token); this function does its own auth for refunds. See docs/MONERIS_PAYMENT.md:
//   supabase functions deploy pay-online --no-verify-jwt
//   supabase secrets set MONERIS_API_KEY=... MONERIS_MERCHANT_ID=... \
//                        MONERIS_HT_PROFILE_ID=... MONERIS_ENV=qa
//
// Routes:
//   GET  ?order_id=<uuid>                  → serve the Hosted Tokenization page
//   POST ?action=verify {order_id, token}  → charge the token + write paid
//   POST ?action=refund {order_id}         → restaurant-authenticated refund

import {
  htIframeSrc,
  htOrigin,
  MonerisConfig,
  purchaseWithCard,
  purchaseWithToken,
  refundPayment,
} from "./moneris.ts";

const env = (k: string) => Deno.env.get(k) ?? "";

const SUPABASE_URL = env("SUPABASE_URL");
const SERVICE_ROLE = env("SUPABASE_SERVICE_ROLE_KEY");
const ANON_KEY = env("SUPABASE_ANON_KEY");

function monerisConfig(): MonerisConfig {
  return {
    apiKey: env("MONERIS_API_KEY"),
    clientId: env("MONERIS_CLIENT_ID"),
    clientSecret: env("MONERIS_CLIENT_SECRET"),
    merchantId: env("MONERIS_MERCHANT_ID"),
    htProfileId: env("MONERIS_HT_PROFILE_ID"),
    env: env("MONERIS_ENV") === "prod" ? "prod" : "qa",
    apiVersion: env("MONERIS_API_VERSION") || "2025-08-14",
  };
}

/// A <=36-char idempotency key per (order, operation) so a retried call can't
/// double-charge or double-refund. The order id is a 36-char uuid → strip the
/// dashes (32) and add a one-char suffix.
const idemKey = (orderId: string, suffix: string) =>
  `${orderId.replaceAll("-", "")}${suffix}`;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

function headersWith(contentType: string): Headers {
  const h = new Headers(CORS);
  h.set("Content-Type", contentType);
  return h;
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: headersWith("application/json; charset=utf-8"),
  });

const html = (body: string, status = 200) =>
  new Response(body, {
    status,
    headers: headersWith("text/html; charset=utf-8"),
  });

// --- Supabase REST (service role: bypasses RLS to read orders / write paid) ---

function restHeaders() {
  return {
    apikey: SERVICE_ROLE,
    Authorization: `Bearer ${SERVICE_ROLE}`,
    "Content-Type": "application/json",
  };
}

interface OrderRow {
  id: string;
  lines: unknown[];
  status: string;
  payment_status: string;
  processor_ref: string | null;
}

async function readOrder(orderId: string): Promise<OrderRow | null> {
  const resp = await fetch(
    `${SUPABASE_URL}/rest/v1/online_orders?id=eq.${orderId}` +
      `&select=id,lines,status,payment_status,processor_ref`,
    { headers: restHeaders() },
  );
  if (!resp.ok) return null;
  const rows = await resp.json();
  return Array.isArray(rows) && rows.length ? rows[0] as OrderRow : null;
}

async function patchOrder(orderId: string, patch: Record<string, unknown>) {
  await fetch(`${SUPABASE_URL}/rest/v1/online_orders?id=eq.${orderId}`, {
    method: "PATCH",
    headers: restHeaders(),
    body: JSON.stringify(patch),
  });
}

/// Tax rate (basis points) from the published menu — the SAME canonical row the
/// customer app reads (`id = 'menu'`), so the charge's tax matches the total the
/// customer saw at checkout. (Reading the newest row by `published_at` could
/// pick a stray row whose taxRateBp is 0 — the cause of tax-less charges.)
async function publishedTaxRateBp(): Promise<number> {
  const resp = await fetch(
    `${SUPABASE_URL}/rest/v1/published_menu?select=menu&id=eq.menu&limit=1`,
    { headers: restHeaders() },
  );
  if (!resp.ok) return 0;
  const rows = await resp.json();
  const menu = Array.isArray(rows) && rows.length ? rows[0].menu : null;
  return (menu?.taxRateBp as number) ?? 0;
}

/// Recompute the charge from the order's own lines + published tax. Mirrors
/// domain OrderTotals.compute (tax = round(subtotal*bp/10000); the service fee
/// is waived online so the charge matches the customer's shown estimate).
function chargeCents(lines: unknown[], taxRateBp: number): number {
  let subtotal = 0;
  for (const raw of lines) {
    const l = raw as Record<string, unknown>;
    let unit = (l.priceSnapshot as number) ?? 0;
    for (const m of (l.modifiers as Record<string, unknown>[] ?? [])) {
      unit += (m.priceDeltaSnapshot as number) ?? 0;
    }
    subtotal += unit * ((l.qty as number) ?? 0);
  }
  const tax = Math.round((subtotal * taxRateBp) / 10000);
  return subtotal + tax;
}

/// The amount to charge for an order. Honors MONERIS_TEST_AMOUNT_CENTS when set
/// — a SANDBOX-ONLY override, because the QA Penny-Value Simulator picks the
/// response from the amount's cents (so a real total like $15.81 can hit an
/// "error" penny). Set it to a known-approved amount (e.g. 100) to test the
/// wiring end-to-end, then UNSET it for real charges.
async function effectiveCents(order: OrderRow): Promise<number> {
  const override = Number(env("MONERIS_TEST_AMOUNT_CENTS"));
  if (Number.isFinite(override) && override > 0) return override;
  return chargeCents(order.lines, await publishedTaxRateBp());
}

// --- Auth (refund is restaurant-only) ---

async function isRestaurant(token: string | null): Promise<boolean> {
  if (!token) return false;
  const resp = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: { apikey: ANON_KEY, Authorization: `Bearer ${token}` },
  });
  if (!resp.ok) return false;
  const user = await resp.json();
  return user?.is_anonymous !== true && !!user?.id;
}

function bearer(req: Request): string | null {
  const h = req.headers.get("authorization") ?? "";
  return h.toLowerCase().startsWith("bearer ") ? h.slice(7) : null;
}

// --- Hosted Tokenization page ---

function checkoutPage(
  orderId: string,
  cfg: MonerisConfig,
  amountCents: number,
): string {
  const amount = `$${(amountCents / 100).toFixed(2)}`;
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Secure payment</title>
  <style>
    body { font-family: system-ui, sans-serif; margin: 0; padding: 16px; max-width: 480px; }
    #ht { width: 100%; height: 240px; border: 1px solid #ccc; border-radius: 8px; }
    button { font-size: 16px; padding: 12px 20px; width: 100%; margin-top: 12px;
             border: 0; border-radius: 8px; background: #1463ff; color: #fff; }
    #msg { margin-top: 12px; color: #b00; }
    #done { display: none; text-align: center; padding: 48px 16px; }
  </style>
</head>
<body>
  <div id="pay">
    <h2 style="margin:0 0 12px">Pay ${amount}</h2>
    <iframe id="ht" src="${htIframeSrc(cfg)}"></iframe>
    <button id="btn" type="button">Pay ${amount}</button>
    <div id="msg"></div>
  </div>
  <div id="done"><h1>✅ Payment complete</h1><p>You can return to the app.</p></div>
  <script>
    var orderId = ${JSON.stringify(orderId)};
    var origin = ${JSON.stringify(htOrigin(cfg))};
    var msg = document.getElementById('msg');

    document.getElementById('btn').onclick = function () {
      msg.textContent = '';
      // Ask Moneris's iframe to tokenize the entered card.
      document.getElementById('ht').contentWindow.postMessage('tokenize', origin);
    };

    window.addEventListener('message', function (e) {
      if (e.origin !== origin) return;
      var data;
      try { data = typeof e.data === 'string' ? JSON.parse(e.data) : e.data; }
      catch (_) { return; }
      // Moneris HT returns { responseCode:[...], dataKey, errorMessage, bin }.
      if (!data || !data.dataKey) {
        msg.textContent = (data && data.errorMessage) || 'Card was not accepted.';
        return;
      }
      fetch(location.pathname + location.search + '&action=verify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ order_id: orderId, token: data.dataKey })
      }).then(function (r) { return r.json(); }).then(function (out) {
        if (out && out.paid) {
          document.getElementById('pay').style.display = 'none';
          document.getElementById('done').style.display = 'block';
        } else {
          var d = out && out.detail ? ' — ' + JSON.stringify(out.detail) : '';
          msg.textContent = 'Payment failed: ' + ((out && out.reason) || 'declined') + d
            + ' [HT token = ' + data.dataKey + ']';
        }
      }).catch(function (e) { msg.textContent = 'Payment could not be completed: ' + e; });
    });
  </script>
</body>
</html>`;
}

// --- Handlers ---

async function handleGet(orderId: string): Promise<Response> {
  const order = await readOrder(orderId);
  if (!order) return html("<h1>Order not found</h1>", 404);
  if (order.payment_status === "paid") {
    return html("<h1>Already paid</h1><p>You can return to the app.</p>");
  }
  const cents = await effectiveCents(order);
  if (cents <= 0) return html("<h1>Nothing to pay</h1>", 400);
  return html(checkoutPage(orderId, monerisConfig(), cents));
}

async function handleVerify(req: Request): Promise<Response> {
  const { order_id, token } = await req.json().catch(() => ({}));
  if (!order_id || !token) return json({ error: "bad request" }, 400);
  const order = await readOrder(order_id);
  if (!order) return json({ error: "not found" }, 404);
  if (order.payment_status === "paid") return json({ paid: true }); // idempotent

  const expected = await effectiveCents(order);
  let r;
  try {
    r = await purchaseWithToken(monerisConfig(), {
      token,
      amountCents: expected,
      orderId: order_id,
      idempotencyKey: idemKey(order_id, "p"),
    });
  } catch (e) {
    // Surface the real cause (e.g. an expired OAuth2 secret) instead of a blank
    // 500 the client can't read.
    const msg = e instanceof Error ? e.message : String(e);
    return json({ paid: false, reason: `charge_error: ${msg}` }, 502);
  }
  if (!r.approved) {
    return json({ paid: false, reason: "declined", detail: r.raw }, 402);
  }
  // We compute `expected` from the order and send it as the charge amount, so
  // the charge IS the expected amount by construction. This is a belt-and-braces
  // echo check — only enforced when Moneris returns the amount (don't block a
  // good payment if the field is absent).
  if (r.amountCents != null && r.amountCents !== expected) {
    return json({ paid: false, reason: "amount_mismatch" }, 409);
  }
  await patchOrder(order_id, {
    payment_status: "paid",
    paid_at: new Date().toISOString(),
    processor_ref: r.paymentId,
  });
  return json({ paid: true });
}

async function handleRefund(req: Request): Promise<Response> {
  if (!await isRestaurant(bearer(req))) {
    return json({ error: "forbidden" }, 403);
  }
  const { order_id } = await req.json().catch(() => ({}));
  if (!order_id) return json({ error: "bad request" }, 400);
  const order = await readOrder(order_id);
  if (!order) return json({ error: "not found" }, 404);
  if (order.payment_status !== "paid" || !order.processor_ref) {
    return json({ error: "not refundable" }, 409);
  }
  const cents = await effectiveCents(order);
  const result = await refundPayment(monerisConfig(), {
    paymentId: order.processor_ref,
    amountCents: cents,
    idempotencyKey: idemKey(order_id, "r"),
  });
  if (!result.success) {
    return json({ refunded: false, detail: result.raw }, 502);
  }
  await patchOrder(order_id, { payment_status: "refunded" });
  return json({ refunded: true });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const url = new URL(req.url);
  const action = url.searchParams.get("action");

  try {
    // DEBUG: GET ?action=testcard charges a $1 direct test card through the same
    // path/headers as the token. Pass &order_id=<uuid> to also test the long
    // orderId. Isolates token (Moneris config) vs our request mechanics.
    if (req.method === "GET" && action === "testcard") {
      const orderId = url.searchParams.get("order_id") ?? `tc-${Date.now()}`;
      const r = await purchaseWithCard(monerisConfig(), {
        amountCents: 100,
        orderId,
        idempotencyKey: `tc-${Date.now()}`,
      });
      return json({
        testcard: true,
        orderId,
        approved: r.approved,
        paymentId: r.paymentId,
        raw: r.raw,
      });
    }
    if (req.method === "GET") {
      const orderId = url.searchParams.get("order_id");
      if (!orderId) return html("<h1>Missing order_id</h1>", 400);
      return await handleGet(orderId);
    }
    if (req.method === "POST" && action === "verify") {
      return await handleVerify(req);
    }
    if (req.method === "POST" && action === "refund") {
      return await handleRefund(req);
    }
    return json({ error: "not found" }, 404);
  } catch (e) {
    // Never return a bare 500 the client can't parse — always JSON with a reason.
    const msg = e instanceof Error ? e.message : String(e);
    return json({ paid: false, reason: `server_error: ${msg}` }, 500);
  }
});
