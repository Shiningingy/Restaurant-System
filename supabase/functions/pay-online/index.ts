// Supabase Edge Function: pay-online
//
// The trusted backend for online card payment (Phase 7). The restaurant deploys
// this on its OWN Supabase project with its OWN processor credentials — we host
// nothing and never hold a key. Card data goes customer → the processor's hosted
// card field directly; this function only ever sees a token/result.
//
// PROCESSOR is selectable via paymentProvider(): Stripe (Payment Element) when
// STRIPE_SECRET_KEY is set, else Helcim (HelcimPay.js) when HELCIM_API_TOKEN is
// set, else Moneris (Hosted Tokenization). Force one with
// PAYMENT_PROVIDER=stripe|helcim|moneris. Each vendor's wire format lives in its
// own module — stripe.ts / helcim.ts / moneris.ts.
// See docs/STRIPE_PAYMENT.md, docs/HELCIM_PAYMENT.md, docs/MONERIS_PAYMENT.md.
//
// It is the ONLY writer of online_orders.payment_status = 'paid': it confirms the
// payment server-side and recomputes the amount from the order (so nobody pays
// $0.01 for a $50 order) before trusting it.
//
// Deploy WITHOUT JWT verification (the customer's browser opens the GET with no
// token); this function does its own auth for refunds:
//   supabase functions deploy pay-online --no-verify-jwt
//   # Stripe:  supabase secrets set STRIPE_SECRET_KEY=sk_test_... \
//   #                        STRIPE_PUBLISHABLE_KEY=pk_test_... STRIPE_CURRENCY=cad
//   # Helcim:  supabase secrets set HELCIM_API_TOKEN=... HELCIM_CURRENCY=CAD
//   # Moneris: supabase secrets set MONERIS_API_KEY=... MONERIS_MERCHANT_ID=... \
//   #                        MONERIS_HT_PROFILE_ID=... MONERIS_ENV=qa
//
// Routes:
//   GET  ?order_id=<uuid>                 → serve the hosted checkout page
//   POST ?action=verify {order_id, ...}   → confirm the payment + write paid
//   POST ?action=refund {order_id}        → restaurant-authenticated refund

import {
  diagnose as monerisDiagnose,
  htIframeSrc,
  htOrigin,
  MonerisConfig,
  purchaseWithToken,
  refundPayment as monerisRefund,
} from "./moneris.ts";
import {
  diagnose as helcimDiagnose,
  HELCIM_PAY_SCRIPT,
  HelcimConfig,
  initializeCheckout,
  refundPayment as helcimRefund,
  validatePaymentHash,
} from "./helcim.ts";
import { chargeWithTipCents } from "./amount.ts";
import {
  createCheckoutSession,
  createPaymentIntent,
  diagnose as stripeDiagnose,
  refundPayment as stripeRefund,
  retrieveCheckoutSession,
  retrievePaymentIntent,
  STRIPE_JS,
  StripeConfig,
} from "./stripe.ts";

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
    htHost: env("MONERIS_HT_HOST"),
    env: env("MONERIS_ENV") === "prod" ? "prod" : "qa",
    apiVersion: env("MONERIS_API_VERSION") || "2025-08-14",
  };
}

function helcimConfig(): HelcimConfig {
  return {
    apiToken: env("HELCIM_API_TOKEN"),
    currency: env("HELCIM_CURRENCY") || "CAD",
  };
}

function stripeConfig(): StripeConfig {
  return {
    secretKey: env("STRIPE_SECRET_KEY"),
    publishableKey: env("STRIPE_PUBLISHABLE_KEY"),
    // Stripe wants a lowercase ISO code.
    currency: (env("STRIPE_CURRENCY") || "cad").toLowerCase(),
  };
}

/// Which Stripe front-end to use.
///   "checkout" (DEFAULT) — redirect to Stripe's own hosted page. We render no
///     payment HTML at all, so there is no card UI of ours to maintain, and the
///     page is served by Stripe as real text/html (Supabase serves OUR responses
///     as text/plain, which is what forces the heavyweight webview).
///   "element" — render Payment Element on our own page. Keeps our branding, at
///     the cost of hosting the card UI and needing a webview that can relabel it.
/// Override with STRIPE_UI=element.
function stripeUi(): "checkout" | "element" {
  return env("STRIPE_UI").toLowerCase() === "element" ? "element" : "checkout";
}

/// Which processor this deployment uses. Auto-selects the first one that is
/// configured — Stripe, then Helcim, then Moneris — so existing deployments keep
/// working untouched and adding a key is all it takes to switch. Override
/// explicitly with PAYMENT_PROVIDER=stripe|helcim|moneris.
function paymentProvider(): "stripe" | "helcim" | "moneris" {
  const p = env("PAYMENT_PROVIDER").toLowerCase();
  if (p === "stripe" || p === "helcim" || p === "moneris") return p;
  if (env("STRIPE_SECRET_KEY")) return "stripe";
  return env("HELCIM_API_TOKEN") ? "helcim" : "moneris";
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

/// Supabase serves Edge Function output as text/plain, so anything we return is
/// shown to the customer as literal characters. For the pages the customer
/// actually SEES after paying, send bare prose rather than markup.
const text = (body: string, status = 200) =>
  new Response(body, {
    status,
    headers: headersWith("text/plain; charset=utf-8"),
  });

/// A payment page we could not set up. The customer gets one plain, actionable
/// sentence; the real cause — which for Stripe includes the full API error body
/// and request id — goes to the function logs, never onto their screen.
function setupFailed(detail: string): Response {
  console.error(`pay-online setup failed: ${detail}`);
  return text(
    "Payment is temporarily unavailable. Please try again, " +
      "or choose to pay at the counter.",
    502,
  );
}

const redirect = (location: string) => {
  const h = new Headers(CORS);
  h.set("Location", location);
  return new Response(null, { status: 302, headers: h });
};

/// This function's **publicly reachable** URL.
///
/// Supabase's edge runtime strips the `/functions/v1` prefix before the request
/// reaches us, so `url.pathname` is a bare `/pay-online`. Echoing that straight
/// back to Stripe as a `success_url` sent the paying customer to
/// `https://<ref>.supabase.co/pay-online`, which the API gateway rejects with
/// `{"error":"requested path is invalid"}` — a 404 shown *after* their card had
/// been charged. Always rebuild the address from the outside world's point of
/// view, never from the path we happen to be handed.
///
/// Tolerates the prefix already being present so a local `supabase functions
/// serve` (which does pass the full path) keeps working.
function publicFunctionUrl(url: URL): string {
  const path = url.pathname.startsWith("/functions/v1/")
    ? url.pathname
    : `/functions/v1${url.pathname}`;
  return `${url.origin}${path}`;
}

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
  pay_secret?: string | null; // Helcim only — see readOrder()
  tip_cents?: number | null; // optional per-deployment column — see readOrder()
}

async function readOrder(orderId: string): Promise<OrderRow | null> {
  // `pay_secret` is a Helcim-only column (it stashes that vendor's one-time
  // session secret between the GET and the POST). Only ask for it when Helcim is
  // the provider, so a Stripe or Moneris deployment needs no extra DDL — asking
  // PostgREST for a column that doesn't exist is a hard 400.
  const base = "id,lines,status,payment_status,processor_ref" +
    (paymentProvider() === "helcim" ? ",pay_secret" : "");
  // `tip_cents` is likewise OPTIONAL per deployment (see docs/CLOUD_SECURITY.md).
  // Ask for it, but never let a project that skipped that DDL break payment
  // outright — fall back to the base columns, which simply means a zero tip.
  for (const cols of [`${base},tip_cents`, base]) {
    const resp = await fetch(
      `${SUPABASE_URL}/rest/v1/online_orders?id=eq.${orderId}&select=${cols}`,
      { headers: restHeaders() },
    );
    if (!resp.ok) continue;
    const rows = await resp.json();
    return Array.isArray(rows) && rows.length ? rows[0] as OrderRow : null;
  }
  return null;
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
  // FAIL CLOSED. Returning 0 on a transient failure silently drops tax from a
  // live charge (undercharging the shop), and — because the GET and the verify
  // each re-read this — a blip on only one of them makes the two amounts
  // disagree AFTER the card was captured. Refuse to price the order instead.
  if (!resp.ok) {
    throw new Error(`tax rate lookup failed: HTTP ${resp.status}`);
  }
  const rows = await resp.json();
  if (!Array.isArray(rows) || rows.length === 0) {
    throw new Error("no published menu — cannot price this order");
  }
  // A genuinely tax-free shop legitimately publishes 0; only a MISSING row is
  // an error, which the check above already caught.
  return (rows[0].menu?.taxRateBp as number) ?? 0;
}

/// The amount to charge for an order: the recomputed total (lines + tax, service
/// fee waived online) PLUS the tip the customer chose at checkout.
///
/// The tip MUST be included: the customer's checkout screen shows
/// `subtotal + tax + tip` as the amount they are agreeing to pay, so charging
/// anything less silently loses the staff their tip.
///
/// There is deliberately NO test-amount override here. A sandbox-only override
/// once existed for Moneris's penny-value simulator; it was provider-agnostic,
/// so it silently forced Stripe charges to a fixed amount while the verify step
/// compared against that same override and never flagged it — i.e. undercharging
/// with no error anywhere. Stripe picks outcomes from the test CARD NUMBER, so
/// nothing needs it. Test with real totals.
async function effectiveCents(order: OrderRow): Promise<number> {
  return chargeWithTipCents(
    order.lines,
    await publishedTaxRateBp(),
    order.tip_cents,
  );
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
      // No dataKey = the IFRAME (Hosted Tokenization) rejected the card — this is
      // a profile/source-domain config issue, NOT the /payments charge. Label it
      // so it can't be confused with a charge/credentials failure.
      if (!data || !data.dataKey) {
        // Diagnostics go to the console (visible to the operator via devtools),
        // never onto the customer's screen.
        if (window.console) console.error('tokenize failed', data);
        msg.textContent = 'That card could not be read. Please check the number '
          + 'and try again, or use a different card.';
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
          // Never render the processor's raw response to the customer.
          var d = '';
          if (window.console) console.error('verify failed', out);
          msg.textContent = 'Payment failed: ' + ((out && out.reason) || 'declined') + d;
        }
      }).catch(function (e) { msg.textContent = 'Payment could not be completed: ' + e; });
    });
  </script>
</body>
</html>`;
}

/// The HelcimPay.js hosted-modal checkout page. Loads HelcimPay.js, opens the
/// modal for the pre-initialized checkoutToken, and on the SUCCESS event posts
/// the signed { data, hash } to ?action=verify for server-side hash validation.
/// Card data is entered only inside Helcim's modal — never in our DOM.
function helcimCheckoutPage(
  orderId: string,
  checkoutToken: string,
  amountCents: number,
): string {
  const amount = `$${(amountCents / 100).toFixed(2)}`;
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Secure payment</title>
  <script type="text/javascript" src="${HELCIM_PAY_SCRIPT}"></script>
  <style>
    body { font-family: system-ui, sans-serif; margin: 0; padding: 16px; max-width: 480px; }
    button { font-size: 16px; padding: 12px 20px; width: 100%; margin-top: 12px;
             border: 0; border-radius: 8px; background: #1463ff; color: #fff; }
    #msg { margin-top: 12px; color: #b00; }
    #done { display: none; text-align: center; padding: 48px 16px; }
  </style>
</head>
<body>
  <div id="pay">
    <h2 style="margin:0 0 12px">Pay ${amount}</h2>
    <button id="btn" type="button">Pay ${amount}</button>
    <div id="msg"></div>
  </div>
  <div id="done"><h1>✅ Payment complete</h1><p>You can return to the app.</p></div>
  <script>
    var orderId = ${JSON.stringify(orderId)};
    var checkoutToken = ${JSON.stringify(checkoutToken)};
    var eventName = 'helcim-pay-js-' + checkoutToken;
    var msg = document.getElementById('msg');

    function openModal() {
      msg.textContent = '';
      // Renders Helcim's hosted card modal for this checkout session.
      appendHelcimPayIframe(checkoutToken);
    }
    document.getElementById('btn').onclick = openModal;
    openModal(); // open immediately; the button re-opens if the customer closes it

    window.addEventListener('message', function (e) {
      if (!e.data || e.data.eventName !== eventName) return;
      if (e.data.eventStatus === 'ABORTED') {
        msg.textContent = 'Payment cancelled or declined: '
          + (e.data.eventMessage || '');
        return;
      }
      if (e.data.eventStatus !== 'SUCCESS') return; // HIDE etc. — ignore

      var resp;
      try { resp = JSON.parse(e.data.eventMessage); }
      catch (_) { msg.textContent = 'Unexpected payment response.'; return; }

      fetch(location.pathname + location.search + '&action=verify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ order_id: orderId, data: resp.data, hash: resp.hash })
      }).then(function (r) { return r.json(); }).then(function (out) {
        if (out && out.paid) {
          document.getElementById('pay').style.display = 'none';
          document.getElementById('done').style.display = 'block';
        } else {
          // Never render the processor's raw response to the customer.
          var d = '';
          msg.textContent = 'Payment failed: ' + ((out && out.reason) || 'declined') + d;
        }
      }).catch(function (err) {
        msg.textContent = 'Payment could not be completed: ' + err;
      });
    });
  </script>
</body>
</html>`;
}

/// The Stripe Payment Element checkout page. Mounts Stripe's hosted card iframe
/// for the pre-created PaymentIntent and confirms it in-place; on success it posts
/// the PaymentIntent id to ?action=verify, which re-reads it from Stripe before
/// trusting it. Card data is entered only inside Stripe's iframe — never in our DOM.
///
/// 3-D Secure: `redirect: 'if_required'` keeps the common case inside the page
/// (important in an in-app WebView). If a card genuinely demands a redirect,
/// Stripe returns to `return_url` (this same page) with ?payment_intent=… , which
/// we detect on load and verify — so both paths end at the same place.
function stripeCheckoutPage(
  orderId: string,
  clientSecret: string,
  publishableKey: string,
  amountCents: number,
): string {
  const amount = `$${(amountCents / 100).toFixed(2)}`;
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Secure payment</title>
  <script src="${STRIPE_JS}"></script>
  <style>
    body { font-family: system-ui, sans-serif; margin: 0; padding: 16px; max-width: 480px; }
    #payment-element { margin-top: 12px; }
    button { font-size: 16px; padding: 12px 20px; width: 100%; margin-top: 16px;
             border: 0; border-radius: 8px; background: #1463ff; color: #fff; }
    button[disabled] { opacity: .6; }
    #msg { margin-top: 12px; color: #b00; }
    #done { display: none; text-align: center; padding: 48px 16px; }
  </style>
</head>
<body>
  <div id="pay">
    <h2 style="margin:0 0 12px">Pay ${amount}</h2>
    <div id="payment-element"></div>
    <button id="btn" type="button">Pay ${amount}</button>
    <div id="msg"></div>
  </div>
  <div id="done"><h1>✅ Payment complete</h1><p>You can return to the app.</p></div>
  <script>
    var orderId = ${JSON.stringify(orderId)};
    var clientSecret = ${JSON.stringify(clientSecret)};
    var msg = document.getElementById('msg');
    var btn = document.getElementById('btn');
    var stripe = Stripe(${JSON.stringify(publishableKey)});
    var elements = stripe.elements({ clientSecret: clientSecret });
    elements.create('payment').mount('#payment-element');

    function fail(text) { msg.textContent = text; btn.disabled = false; }

    // Ask OUR server to confirm with Stripe before anything is marked paid — the
    // browser saying "succeeded" is never enough on its own.
    function verify(paymentIntentId) {
      fetch(location.pathname + location.search + '&action=verify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ order_id: orderId, payment_intent_id: paymentIntentId })
      }).then(function (r) { return r.json(); }).then(function (out) {
        if (out && out.paid) {
          document.getElementById('pay').style.display = 'none';
          document.getElementById('done').style.display = 'block';
        } else {
          // Never render the processor's raw response to the customer.
          var d = '';
          fail('Payment failed: ' + ((out && out.reason) || 'declined') + d);
        }
      }).catch(function (e) { fail('Payment could not be completed: ' + e); });
    }

    // Returning from a 3-D Secure redirect: Stripe appends payment_intent to the
    // return_url, so pick up where we left off instead of asking them to pay twice.
    var returned = new URLSearchParams(location.search).get('payment_intent');
    if (returned) { btn.disabled = true; verify(returned); }

    btn.onclick = function () {
      msg.textContent = '';
      btn.disabled = true;
      stripe.confirmPayment({
        elements: elements,
        confirmParams: { return_url: location.href },
        redirect: 'if_required'
      }).then(function (res) {
        if (res.error) { fail(res.error.message || 'Card was declined.'); return; }
        var pi = res.paymentIntent;
        if (pi && pi.status === 'succeeded') { verify(pi.id); }
        else { fail('Payment not completed (' + (pi ? pi.status : 'unknown') + ').'); }
      });
    };
  </script>
</body>
</html>`;
}

// --- Handlers ---

async function handleGet(orderId: string, url: URL): Promise<Response> {
  const order = await readOrder(orderId);
  if (!order) return html("<h1>Order not found</h1>", 404);
  if (order.payment_status === "paid") {
    return html("<h1>Already paid</h1><p>You can return to the app.</p>");
  }
  const cents = await effectiveCents(order);
  if (cents <= 0) return html("<h1>Nothing to pay</h1>", 400);
  const provider = paymentProvider();
  if (provider === "stripe") {
    const cfg = stripeConfig();

    // DEFAULT: hand the whole payment page to Stripe. We render nothing.
    if (stripeUi() === "checkout") {
      const base = publicFunctionUrl(url);
      let session;
      try {
        session = await createCheckoutSession(cfg, {
          amountCents: cents,
          orderId,
          // Stripe substitutes the real id into {CHECKOUT_SESSION_ID}.
          successUrl:
            `${base}?order_id=${orderId}&action=return&session_id={CHECKOUT_SESSION_ID}`,
          cancelUrl: `${base}?order_id=${orderId}&action=cancel`,
          idempotencyKey: idemKey(orderId, "s"),
        });
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        return setupFailed(msg);
      }
      return redirect(session.url);
    }

    // STRIPE_UI=element: our own page hosting Stripe's Payment Element.
    if (!cfg.publishableKey) {
      return html(
        "<h1>Payment setup failed</h1><p>STRIPE_PUBLISHABLE_KEY is not set.</p>",
        500,
      );
    }
    let intent;
    try {
      // Keyed on the order, so reloading this page reuses the SAME PaymentIntent
      // instead of creating a new one each time.
      intent = await createPaymentIntent(cfg, {
        amountCents: cents,
        orderId,
        idempotencyKey: idemKey(orderId, "i"),
      });
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      return setupFailed(msg);
    }
    return html(
      stripeCheckoutPage(
        orderId,
        intent.clientSecret,
        cfg.publishableKey,
        cents,
      ),
    );
  }
  if (provider === "helcim") {
    let init;
    try {
      init = await initializeCheckout(helcimConfig(), {
        amountCents: cents,
        orderId,
      });
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      return setupFailed(msg);
    }
    // Stash the secretToken so ?action=verify can validate the result hash
    // (this function is stateless between the GET and the POST).
    await patchOrder(orderId, { pay_secret: init.secretToken });
    return html(helcimCheckoutPage(orderId, init.checkoutToken, cents));
  }
  return html(checkoutPage(orderId, monerisConfig(), cents));
}

async function handleVerifyMoneris(req: Request): Promise<Response> {
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
    // The processor's raw body and correlation id are operator diagnostics, not
    // customer-facing content — log them, return only the outcome.
    console.error(
      `moneris declined order=${order_id} http=${r.httpStatus} ` +
        `corr=${r.correlationId} body=${JSON.stringify(r.raw)}`,
    );
    return json({ paid: false, reason: "declined" }, 402);
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

/// Verify for HelcimPay.js: the browser posts the modal's signed SUCCESS payload
/// { data, hash }; we validate the hash with the stashed secretToken (proving it
/// came from Helcim), confirm APPROVED + the amount, then write paid. The charge
/// already happened in the modal — this is authenticity + amount confirmation.
async function handleVerifyHelcim(req: Request): Promise<Response> {
  const body = await req.json().catch(() => ({}));
  const order_id = body.order_id as string | undefined;
  const data = body.data as Record<string, unknown> | undefined;
  const hash = body.hash as string | undefined;
  if (!order_id || !data || !hash) {
    return json({ paid: false, reason: "bad request" }, 400);
  }
  const order = await readOrder(order_id);
  if (!order) return json({ error: "not found" }, 404);
  if (order.payment_status === "paid") return json({ paid: true }); // idempotent
  if (!order.pay_secret) return json({ paid: false, reason: "no_session" }, 409);

  const ok = await validatePaymentHash(order.pay_secret, data, hash);
  if (!ok) return json({ paid: false, reason: "hash_mismatch" }, 400);

  const status = `${data.status ?? ""}`.toUpperCase();
  if (status !== "APPROVED") {
    return json({ paid: false, reason: "declined", detail: { status } }, 402);
  }
  // The amount was fixed server-side at initialize; re-check the returned amount
  // (Helcim reports DOLLARS) against what we expect (cents) — belt-and-braces.
  const expected = await effectiveCents(order);
  const paidCents = Math.round(Number(data.amount) * 100);
  if (Number.isFinite(paidCents) && paidCents !== expected) {
    return json(
      { paid: false, reason: "amount_mismatch", detail: { expected, paidCents } },
      409,
    );
  }
  await patchOrder(order_id, {
    payment_status: "paid",
    paid_at: new Date().toISOString(),
    processor_ref: `${data.transactionId ?? ""}`,
    pay_secret: null, // one-time session secret — clear once consumed
  });
  return json({ paid: true });
}

/// Verify for Stripe: the browser posts the PaymentIntent id it just confirmed;
/// we RETRIEVE that intent from Stripe and require succeeded + the exact amount
/// and currency before writing paid. Nothing the browser claims is trusted — the
/// authority is Stripe's own record of the charge.
async function handleVerifyStripe(req: Request): Promise<Response> {
  const body = await req.json().catch(() => ({}));
  const order_id = body.order_id as string | undefined;
  const intentId = body.payment_intent_id as string | undefined;
  if (!order_id || !intentId) {
    return json({ paid: false, reason: "bad request" }, 400);
  }
  const order = await readOrder(order_id);
  if (!order) return json({ error: "not found" }, 404);
  if (order.payment_status === "paid") return json({ paid: true }); // idempotent

  const cfg = stripeConfig();
  let pi;
  try {
    pi = await retrievePaymentIntent(cfg, intentId);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return json({ paid: false, reason: `verify_error: ${msg}` }, 502);
  }
  if (pi.status !== "succeeded") {
    return json(
      { paid: false, reason: "declined", detail: { status: pi.status } },
      402,
    );
  }
  // The amount was fixed server-side when the intent was created; re-check what
  // Stripe actually captured. Both sides are integer cents, so this is exact.
  // Everything below happens AFTER the card was captured, so every failure path
  // here must refund rather than just report — see refundUnreconciled().
  let expected: number;
  try {
    expected = await effectiveCents(order);
  } catch (e) {
    const refunded = await refundUnreconciled(order_id, pi.id, `pricing: ${e}`);
    return json({ paid: false, reason: "pricing_unavailable", refunded }, 503);
  }
  const got = pi.amountReceivedCents ?? pi.amountCents;
  if (got != null && got !== expected) {
    const refunded = await refundUnreconciled(
      order_id,
      pi.id,
      `amount expected=${expected} got=${got}`,
    );
    return json({ paid: false, reason: "amount_mismatch", refunded }, 409);
  }
  if (pi.currency && pi.currency.toLowerCase() !== cfg.currency) {
    const refunded = await refundUnreconciled(
      order_id,
      pi.id,
      `currency expected=${cfg.currency} got=${pi.currency}`,
    );
    return json({ paid: false, reason: "currency_mismatch", refunded }, 409);
  }
  await patchOrder(order_id, {
    payment_status: "paid",
    paid_at: new Date().toISOString(),
    processor_ref: pi.id,
  });
  return json({ paid: true });
}

/// Stripe Checkout's success_url lands here. The customer coming back proves
/// nothing on its own, so we RETRIEVE the session from Stripe and require
/// payment_status = "paid" plus the expected amount before writing paid.
/// The customer app is meanwhile polling online_orders.payment_status, so what
/// this page renders barely matters — the app closes itself once it sees paid.
async function handleStripeReturn(url: URL): Promise<Response> {
  const orderId = url.searchParams.get("order_id");
  const sessionId = url.searchParams.get("session_id");
  if (!orderId || !sessionId) return html("<h1>Missing payment details</h1>", 400);

  const order = await readOrder(orderId);
  if (!order) return html("<h1>Order not found</h1>", 404);
  if (order.payment_status === "paid") {
    return text("✅ Payment complete. You can return to the app.");
  }

  const cfg = stripeConfig();
  let session;
  try {
    session = await retrieveCheckoutSession(cfg, sessionId);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return html(`<h1>Could not confirm payment</h1><p>${msg}</p>`, 502);
  }
  if (session.paymentStatus !== "paid") {
    return text(`Payment not completed (${session.paymentStatus}).`, 402);
  }
  // Captured already — so a failure here must refund, not just report.
  const pi = session.paymentIntentId ?? session.id;
  let expected: number;
  try {
    expected = await effectiveCents(order);
  } catch (e) {
    await refundUnreconciled(orderId, pi, `pricing: ${e}`);
    return text(
      "We couldn't confirm this payment, so it has been refunded. " +
        "Please try again or pay at the counter.",
      503,
    );
  }
  if (
    session.amountTotalCents != null && session.amountTotalCents !== expected
  ) {
    await refundUnreconciled(
      orderId,
      pi,
      `amount expected=${expected} got=${session.amountTotalCents}`,
    );
    return text(
      "We couldn't confirm this payment, so it has been refunded. " +
        "Please try again or pay at the counter.",
      409,
    );
  }
  await patchOrder(orderId, {
    payment_status: "paid",
    paid_at: new Date().toISOString(),
    // Store the PaymentIntent id, not the session id — that is what a refund needs.
    processor_ref: session.paymentIntentId ?? session.id,
  });
  return text("✅ Payment complete. You can return to the app.");
}

// --- Pay by link (staff-initiated, e.g. a phone-in takeout order) ---
//
// Deliberately does NOT touch `online_orders`. The order already exists in the
// POS, so mirroring it into the customer-facing table would make the inbox try
// to rebuild an order that is already there. Instead the POS keeps the returned
// session id and polls it.
//
// That polling is also why pay-by-link needs no webhook: the merchant asks
// Stripe directly, so the answer never depends on the customer's browser coming
// back to us. They can pay and close the tab immediately.

/// Mints a Checkout Session for an amount the STAFF entered, and returns a URL
/// to show as a QR or text to the customer.
///
/// Restaurant-authenticated. The amount comes from the merchant rather than a
/// customer, so there is nothing to defend against here — they are the party
/// being paid. (Customer-initiated payment still recomputes the amount from the
/// order's own lines; see effectiveCents.)
async function handleCreateLink(req: Request, url: URL): Promise<Response> {
  if (!await isRestaurant(bearer(req))) {
    return json({ error: "forbidden" }, 403);
  }
  if (paymentProvider() !== "stripe") {
    return json({ error: "pay_by_link_requires_stripe" }, 400);
  }
  const body = await req.json().catch(() => ({}));
  const orderId = `${body.order_id ?? ""}`;
  const amountCents = Math.round(Number(body.amount_cents));
  const label = typeof body.label === "string" ? body.label : undefined;
  if (!orderId || !Number.isFinite(amountCents) || amountCents <= 0) {
    return json({ error: "bad request" }, 400);
  }
  const base = publicFunctionUrl(url);
  try {
    const session = await createCheckoutSession(stripeConfig(), {
      amountCents,
      orderId,
      label,
      // Stripe substitutes the real id into {CHECKOUT_SESSION_ID}, which lets the
      // landing page confirm with Stripe that this person actually paid instead
      // of thanking anyone who happens to open the URL.
      successUrl: `${base}?action=link_done&session_id={CHECKOUT_SESSION_ID}`,
      cancelUrl: `${base}?action=link_cancelled`,
      // Keyed on order AND amount: re-sending the same link is idempotent (one
      // session, not a pile of them), but editing the order before re-sending
      // correctly mints a new session for the new total.
      idempotencyKey: `${orderId}-link-${amountCents}`,
    });
    return json({ url: session.url, session_id: session.id });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error(`pay-by-link create failed order=${orderId}: ${msg}`);
    return json({ error: "link_failed" }, 502);
  }
}

/// Formats integer cents for display. Kept integer-only (no `cents / 100`
/// rounding) in line with the money rules the rest of the codebase follows.
function formatMoney(cents: number, currency: string | null): string {
  const sign = cents < 0 ? "-" : "";
  const abs = Math.abs(cents);
  const whole = (abs - (abs % 100)) / 100; // exact: the numerator is a multiple of 100
  const frac = String(abs % 100).padStart(2, "0");
  const code = (currency ?? "").toUpperCase();
  return `${sign}$${whole}.${frac}${code ? ` ${code}` : ""}`;
}

/// Where a pay-by-link customer lands once Stripe has taken their money.
///
/// This page writes nothing: the POS polls the session, so the order settles
/// whether or not the customer's browser ever arrives here. It exists purely so
/// that the person who just paid gets an acknowledgement instead of a blank tab.
///
/// It still ASKS Stripe before thanking them. The URL is guessable, and telling
/// someone their payment succeeded when it did not would be worse than saying
/// nothing at all.
///
/// Plain text, deliberately: the Supabase gateway rewrites our `Content-Type` to
/// `text/plain` and sends `X-Content-Type-Options: nosniff`, so markup would be
/// shown to the customer as literal angle brackets. Line breaks are all the
/// formatting available here.
async function handleLinkDone(url: URL): Promise<Response> {
  const sessionId = url.searchParams.get("session_id") ?? "";
  // No id to check — an older link, or a customer who trimmed the URL. The till
  // is the source of truth regardless, so stay warm but don't claim anything.
  if (!sessionId) {
    return text(
      "Thank you — you can close this page.\n\n" +
        "If your payment went through, the restaurant has been notified.",
    );
  }
  let session;
  try {
    session = await retrieveCheckoutSession(stripeConfig(), sessionId);
  } catch (e) {
    // Stripe unreachable from here. The money is unaffected and the till will
    // still see it, so reassure the customer and keep the cause in the logs.
    console.error(`pay-by-link done lookup failed session=${sessionId}: ${e}`);
    return text(
      "Thank you — you can close this page.\n\n" +
        "The restaurant will confirm your payment.",
    );
  }
  if (session.paymentStatus !== "paid") {
    return text(
      "We haven't received this payment yet.\n\n" +
        "If you have just paid, wait a moment and refresh this page. " +
        "Otherwise please contact the restaurant.",
      402,
    );
  }
  const amount = session.amountTotalCents != null
    ? ` of ${formatMoney(session.amountTotalCents, session.currency)}`
    : "";
  return text(
    "✅ Payment received — thank you!\n\n" +
      `Your payment${amount} is confirmed, and the restaurant has been ` +
      "notified. They are preparing your order now.\n\n" +
      "You can close this page.",
  );
}

/// Polls one pay-by-link session. Stripe is the source of truth; we proxy it
/// because only this function holds the secret key.
async function handleLinkStatus(req: Request, url: URL): Promise<Response> {
  if (!await isRestaurant(bearer(req))) {
    return json({ error: "forbidden" }, 403);
  }
  const sessionId = url.searchParams.get("session_id") ?? "";
  if (!sessionId) return json({ error: "bad request" }, 400);
  try {
    const s = await retrieveCheckoutSession(stripeConfig(), sessionId);
    return json({
      paid: s.paymentStatus === "paid",
      status: s.paymentStatus,
      // "open" while the customer still could pay; "expired" once the link is
      // dead. The POS turns the latter into a red dot so staff know to take
      // payment another way rather than waiting forever.
      session_status: s.sessionStatus,
      amount_cents: s.amountTotalCents,
      currency: s.currency,
      // The POS stores this as the payment's terminalRef so a later refund can
      // find the charge.
      payment_intent_id: s.paymentIntentId,
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error(`pay-by-link status failed session=${sessionId}: ${msg}`);
    return json({ error: "status_failed" }, 502);
  }
}

/// The card has ALREADY been captured but we cannot reconcile the payment to the
/// order (the amount or currency disagrees with what we recomputed). Refund it
/// immediately.
///
/// Without this, the function returns an error, the customer app treats the order
/// as unpaid, and `cancelUnpaidOrder` DELETES the row — leaving the customer
/// charged for an order that no longer exists, with nothing to reconcile against.
/// Refunding the full captured amount is deliberate: our expected figure is
/// exactly the thing we've just discovered we can't trust.
async function refundUnreconciled(
  orderId: string,
  paymentIntentId: string,
  reason: string,
): Promise<boolean> {
  console.error(
    `pay-online UNRECONCILED CAPTURE order=${orderId} pi=${paymentIntentId} ` +
      `reason=${reason} — auto-refunding in full`,
  );
  try {
    const r = await stripeRefund(stripeConfig(), {
      paymentIntentId,
      idempotencyKey: idemKey(orderId, "u"),
    });
    if (!r.success) {
      console.error(
        `pay-online AUTO-REFUND FAILED order=${orderId} — MANUAL REFUND REQUIRED: ` +
          JSON.stringify(r.raw),
      );
    }
    return r.success;
  } catch (e) {
    console.error(
      `pay-online AUTO-REFUND THREW order=${orderId} — MANUAL REFUND REQUIRED: ${e}`,
    );
    return false;
  }
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
  const provider = paymentProvider();
  if (provider === "stripe") {
    const result = await stripeRefund(stripeConfig(), {
      paymentIntentId: order.processor_ref,
      amountCents: cents,
      idempotencyKey: idemKey(order_id, "r"),
    });
    if (!result.success) {
      return json({ refunded: false, detail: result.raw }, 502);
    }
    await patchOrder(order_id, { payment_status: "refunded" });
    return json({ refunded: true });
  }
  if (provider === "helcim") {
    const result = await helcimRefund(helcimConfig(), {
      originalTransactionId: order.processor_ref,
      amountCents: cents,
      idempotencyKey: idemKey(order_id, "r"),
    });
    if (!result.success) {
      return json({ refunded: false, detail: result.raw }, 502);
    }
    await patchOrder(order_id, { payment_status: "refunded" });
    return json({ refunded: true });
  }
  const result = await monerisRefund(monerisConfig(), {
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
    // DEBUG: GET ?action=diag dumps the full Moneris exchange (auth method,
    // masked creds, the exact /payments status + headers + raw body) so a
    // credentials/charge failure can be read in full. Optional &token=<ot-…> to
    // test a real token (else a placeholder, which still surfaces auth errors).
    if (req.method === "GET" && action === "diag") {
      // AUTHENTICATED: this route creates real API calls on the merchant's
      // processor account and reports credential metadata. Left open, anyone who
      // learns the function URL could mint payment intents on the account (and,
      // on the Moneris path, fire a real /payments call with their own token and
      // read back the raw response). Restaurant login required, same as refunds.
      if (!await isRestaurant(bearer(req))) {
        return json({ error: "forbidden" }, 403);
      }
      const provider = paymentProvider();
      if (provider === "stripe") {
        const d = await stripeDiagnose(stripeConfig()) as Record<string, unknown>;
        // Report the active front-end too — "why am I not seeing the page I
        // expected" is otherwise invisible from outside.
        return json({ provider, ui: stripeUi(), ...d });
      }
      if (provider === "helcim") {
        const d = await helcimDiagnose(helcimConfig()) as Record<string, unknown>;
        return json({ provider, ...d });
      }
      const token = url.searchParams.get("token");
      return json(await monerisDiagnose(monerisConfig(), token));
    }
    // --- pay by link (staff-initiated) ---
    if (req.method === "POST" && action === "link") {
      return await handleCreateLink(req, url);
    }
    if (req.method === "GET" && action === "link_status") {
      return await handleLinkStatus(req, url);
    }
    // Where a pay-by-link customer lands. Nothing is written here: the POS polls
    // the session, so these pages are courtesy only and it does not matter if
    // the customer closes the tab before seeing them.
    if (req.method === "GET" && action === "link_done") {
      return await handleLinkDone(url);
    }
    if (req.method === "GET" && action === "link_cancelled") {
      return text(
        "Payment cancelled — you have not been charged.\n\n" +
          "Please contact the restaurant if you still want this order.",
      );
    }

    // Stripe Checkout sends the customer back here when they finish or bail.
    if (req.method === "GET" && action === "return") {
      return await handleStripeReturn(url);
    }
    if (req.method === "GET" && action === "cancel") {
      return text("Payment cancelled. You can return to the app.");
    }
    if (req.method === "GET") {
      const orderId = url.searchParams.get("order_id");
      if (!orderId) return html("<h1>Missing order_id</h1>", 400);
      return await handleGet(orderId, url);
    }
    if (req.method === "POST" && action === "verify") {
      switch (paymentProvider()) {
        case "stripe":
          return await handleVerifyStripe(req);
        case "helcim":
          return await handleVerifyHelcim(req);
        default:
          return await handleVerifyMoneris(req);
      }
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
