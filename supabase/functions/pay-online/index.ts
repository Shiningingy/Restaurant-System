// Supabase Edge Function: pay-online
//
// The trusted backend for online card payment (Phase 7). The restaurant
// deploys this on its OWN Supabase project with its OWN Moneris credentials —
// we host nothing and never hold a key. Card data goes customer → Moneris
// directly; this function only ever sees a ticket / receipt / txn id.
//
// It is the ONLY writer of `online_orders.payment_status = 'paid'`: it confirms
// the charge server-to-server with Moneris and recomputes the amount from the
// order (so nobody pays $0.01 for a $50 order) before trusting it.
//
// Deploy WITHOUT JWT verification (the customer's browser opens the GET with no
// token); this function does its own auth for refunds. See docs/MONERIS_PAYMENT.md:
//   supabase functions deploy pay-online --no-verify-jwt
//   supabase secrets set MONERIS_STORE_ID=... MONERIS_API_TOKEN=... \
//                        MONERIS_CHECKOUT_ID=... MONERIS_ENV=qa
//
// Routes:
//   GET  ?order_id=<uuid>           → preload Moneris + serve the hosted page
//   POST ?action=verify {order_id, ticket}  → confirm + write paid (idempotent)
//   POST ?action=refund {order_id}  → restaurant-authenticated refund

import {
  checkoutJsUrl,
  checkoutMode,
  MonerisConfig,
  preload,
  receipt,
  refund,
} from "./moneris.ts";

const env = (k: string) => Deno.env.get(k) ?? "";

const SUPABASE_URL = env("SUPABASE_URL");
const SERVICE_ROLE = env("SUPABASE_SERVICE_ROLE_KEY");
const ANON_KEY = env("SUPABASE_ANON_KEY");

function monerisConfig(): MonerisConfig {
  return {
    storeId: env("MONERIS_STORE_ID"),
    apiToken: env("MONERIS_API_TOKEN"),
    checkoutId: env("MONERIS_CHECKOUT_ID"),
    env: env("MONERIS_ENV") === "prod" ? "prod" : "qa",
  };
}

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS },
  });

const html = (body: string, status = 200) =>
  new Response(body, {
    status,
    headers: { "Content-Type": "text/html; charset=utf-8", ...CORS },
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

/// The restaurant's tax rate (basis points), read from the latest published
/// menu — the same value the customer app and merchant use, so the amount we
/// charge matches the order total the merchant records.
async function publishedTaxRateBp(): Promise<number> {
  const resp = await fetch(
    `${SUPABASE_URL}/rest/v1/published_menu?select=menu&order=published_at.desc&limit=1`,
    { headers: restHeaders() },
  );
  if (!resp.ok) return 0;
  const rows = await resp.json();
  const menu = Array.isArray(rows) && rows.length ? rows[0].menu : null;
  return (menu?.taxRateBp as number) ?? 0;
}

/// Recompute the charge from the order's own lines + published tax. Mirrors
/// domain `OrderTotals.compute` (tax = round(subtotal*bp/10000); the service
/// fee is waived online so the charge matches the customer's shown estimate).
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

// --- Auth (refund is restaurant-only) ---

/// True when [token] belongs to a real (non-anonymous) restaurant user.
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

// --- Hosted checkout page ---

function checkoutPage(ticket: string, orderId: string, mode: string): string {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Secure payment</title>
  <script src="${checkoutJsUrl(monerisConfig().env)}"></script>
  <style>
    body { font-family: system-ui, sans-serif; margin: 0; padding: 16px; }
    #done { display: none; text-align: center; padding: 48px 16px; }
    #done h1 { font-size: 20px; }
  </style>
</head>
<body>
  <div id="monerisCheckout"></div>
  <div id="done"><h1>✅ Payment complete</h1><p>You can return to the app.</p></div>
  <script>
    var orderId = ${JSON.stringify(orderId)};
    var myCheckout = new monerisCheckout();
    myCheckout.setMode(${JSON.stringify(mode)});
    myCheckout.setCheckoutDiv("monerisCheckout");
    function finish() {
      document.getElementById("monerisCheckout").style.display = "none";
      document.getElementById("done").style.display = "block";
    }
    myCheckout.setCallback("payment_complete", function () {
      fetch(location.pathname + "?action=verify", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ order_id: orderId, ticket: ${JSON.stringify(ticket)} })
      }).then(function (r) { return r.json(); })
        .then(finish).catch(finish);
    });
    myCheckout.setCallback("cancel_transaction", function () { history.back(); });
    myCheckout.startCheckout(${JSON.stringify(ticket)});
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
  const taxRateBp = await publishedTaxRateBp();
  const cents = chargeCents(order.lines, taxRateBp);
  if (cents <= 0) return html("<h1>Nothing to pay</h1>", 400);
  const cfg = monerisConfig();
  try {
    const { ticket } = await preload(cfg, {
      txnTotal: (cents / 100).toFixed(2),
      orderNo: orderId,
    });
    return html(checkoutPage(ticket, orderId, checkoutMode(cfg.env)));
  } catch (e) {
    return html(`<h1>Could not start checkout</h1><pre>${e}</pre>`, 502);
  }
}

async function handleVerify(req: Request): Promise<Response> {
  const { order_id, ticket } = await req.json().catch(() => ({}));
  if (!order_id || !ticket) return json({ error: "bad request" }, 400);
  const order = await readOrder(order_id);
  if (!order) return json({ error: "not found" }, 404);
  if (order.payment_status === "paid") return json({ paid: true }); // idempotent

  const cfg = monerisConfig();
  const r = await receipt(cfg, { ticket });
  const expected = chargeCents(order.lines, await publishedTaxRateBp());
  if (!r.approved) return json({ paid: false, reason: "declined" }, 402);
  // Guard against a tampered/short charge: the processor must have taken the
  // amount we computed from the order itself.
  if (r.amountCents !== expected) {
    return json({ paid: false, reason: "amount_mismatch" }, 409);
  }
  await patchOrder(order_id, {
    payment_status: "paid",
    paid_at: new Date().toISOString(),
    processor_ref: r.txnRef,
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
  const cents = chargeCents(order.lines, await publishedTaxRateBp());
  const result = await refund(monerisConfig(), {
    orderNo: order_id,
    txnNumber: order.processor_ref,
    amountCents: cents,
  });
  if (!result.success) {
    return json({ refunded: false, detail: result.detail }, 502);
  }
  await patchOrder(order_id, { payment_status: "refunded" });
  return json({ refunded: true });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const url = new URL(req.url);
  const action = url.searchParams.get("action");

  if (req.method === "GET") {
    const orderId = url.searchParams.get("order_id");
    if (!orderId) return html("<h1>Missing order_id</h1>", 400);
    return handleGet(orderId);
  }
  if (req.method === "POST" && action === "verify") return handleVerify(req);
  if (req.method === "POST" && action === "refund") return handleRefund(req);
  return json({ error: "not found" }, 404);
});
