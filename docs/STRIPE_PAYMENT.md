# Online card payment — Stripe

How the restaurant turns on **online card payment for preorders** using **Stripe**.

Stripe is the default provider: the `pay-online` Edge Function auto-selects it as soon as
`STRIPE_SECRET_KEY` is set. Helcim and Moneris remain in the same function as alternates
(see `HELCIM_PAYMENT.md`, `MONERIS_PAYMENT.md`); nothing about them changes.

---

## Why Stripe

Practical reason, above features and price: **test credentials are issued instantly by
software.** Create an account, stay in Test mode, and the keys are there — no application,
no underwriting, no approval anyone can refuse. Moneris's ISV process stalled for months and
Helcim declined a developer account outright; neither could be unblocked from our side.

Trade-off accepted: Stripe's blended **2.9% + CA$0.30** is dearer than interchange-plus. The
payment layer is provider-swappable by design, so a higher-volume shop can be moved later
without a rewrite.

---

## How it works

Same three-step shape as the other providers — the amount is fixed server-side, the card
never touches our code, and only our own server may mark an order paid.

**Default: Stripe Checkout (`STRIPE_UI=checkout`).** We render no payment page at all.

1. **`GET ?order_id=…`** — the function recomputes the amount from the order's own lines plus
   the published tax rate, creates a **Checkout Session** for exactly that amount, and returns
   a **302 redirect** to `checkout.stripe.com`.
2. **The customer pays on Stripe's own page.** Stripe owns the card fields, 3-D Secure,
   wallets, localization and accessibility. There is no card UI of ours to maintain.
3. **Stripe returns to `?action=return`**, where the function **retrieves the session from
   Stripe** and requires `payment_status = paid` plus the exact amount before writing
   `payment_status = 'paid'` on the order. `processor_ref` stores the **PaymentIntent** id,
   which is what a refund needs.

Step 3 is the important one: the customer coming back proves nothing — only Stripe's own
record of the session is trusted.

This also sidesteps a Supabase quirk. Edge Function responses are served as `text/plain`, so a
page WE render needs a webview that can relabel it; a 302 to Stripe is served by Stripe as real
`text/html`, which any plain webview renders. `PaymentWebView` detects the redirect (it fetches
with `followRedirects = false`) and simply navigates there.

**Fallback: Payment Element (`STRIPE_UI=element`).** Renders our own page hosting Stripe's
Payment Element, keeping our branding, at the cost of hosting the card UI. It creates a
PaymentIntent, and `?action=verify` retrieves that intent before writing paid. Use it only if
the redirect misbehaves in a webview. It needs `STRIPE_PUBLISHABLE_KEY`; Checkout does not.

**No new database column is required.** (Helcim needed `online_orders.pay_secret`; Stripe's
verification is a stateless authenticated lookup, so it needs nothing extra. The function only
asks for `pay_secret` when Helcim is the active provider.)

---

## Setup

### 1. Get test keys (2 minutes, no approval)

1. Register at **dashboard.stripe.com/register**.
2. **Choose Canada** as the country — it is fixed at creation and determines CAD settlement.
3. Stay in **Test mode**. Skip the "activate payments" prompts; live activation is only needed
   to take real money.
4. **Developers → API keys** → copy the **Publishable key** (`pk_test_…`) and
   **Secret key** (`sk_test_…`).

### 2. Database

Nothing new. The `online_orders` payment columns (`payment_status`, `paid_at`,
`processor_ref`) and the `oo_guard_customer_update` trigger that freezes them are the same
ones already listed in `CLOUD_SECURITY.md`. Apply those if this deployment has never had
online payment enabled.

### 3. Secrets + deploy

```bash
npx supabase secrets set \
  STRIPE_SECRET_KEY=sk_test_xxx \
  STRIPE_PUBLISHABLE_KEY=pk_test_xxx \
  STRIPE_CURRENCY=cad

npx supabase functions deploy pay-online --no-verify-jwt
```

(`STRIPE_PUBLISHABLE_KEY` is only used by the `element` fallback — harmless to set either way.)

`--no-verify-jwt` is required: the customer's browser opens the `GET` with no Supabase token.
The function does its own auth for refunds.

> The secret key never leaves the Supabase secret store — it is not in the apps, the repo, or
> the database, and the browser only ever sees the publishable key and a client secret scoped
> to one PaymentIntent.

### 4. Turn it on in the POS

Settings → Online ordering → **Accept online payment**, then republish the menu.

---

## Check the wiring before touching a card

**This route requires the restaurant login** (same auth as refunds) — it creates real
API calls on your processor account, so it must not be open to anyone who learns the
function URL. Get a token and call it:

```bash
TOKEN=$(curl -s "https://<project>.supabase.co/auth/v1/token?grant_type=password" \
  -H "apikey: <anon-key>" -H "Content-Type: application/json" \
  -d '{"email":"<merchant-email>","password":"<password>"}' | jq -r .access_token)

curl -s "https://<project>.supabase.co/functions/v1/pay-online?action=diag" \
  -H "Authorization: Bearer $TOKEN"
```

Expect:

```json
{ "provider": "stripe", "mode": "test", "createIntentOk": true, "paymentIntentId": "...abc123" }
```

- `createIntentOk: false` → the secret key is wrong or unset; `error` carries Stripe's own message.
- `mode: "LIVE — real money"` → you have a live key in place. Stop and swap it for `sk_test_…`
  unless you genuinely mean to charge real cards.

The diagnostic cancels the intent it creates, so it leaves nothing behind.

---

## Test cards

Any future expiry date, any CVC, any postal code.

| Card | What it does |
|---|---|
| `4242 4242 4242 4242` | Succeeds |
| `4000 0025 0000 3155` | Requires 3-D Secure — **test this one**, it exercises the redirect path in the WebView |
| `4000 0000 0000 9995` | Declined (insufficient funds) |
| `4000 0000 0000 0002` | Declined (generic) |

## End-to-end test

1. In the customer app, add items and check out with **Pay online**.
2. The payment page opens in the in-app WebView showing `Pay $X`.
3. Pay with `4242…` → the page shows **Payment complete**, the app returns to the status
   screen showing paid, and the order auto-accepts into the POS inbox.
4. In the Stripe dashboard (**Payments**), the charge appears for the same amount, with
   `metadata.order_id` matching the order.
5. Repeat with `4000 0025 0000 3155` to confirm 3-D Secure completes inside the WebView.
6. Repeat with `4000 0000 0000 9995` and confirm the order is **not** marked paid.
7. **Refund:** open the paid order in the POS and refund it; confirm the order voids locally
   and the refund shows in Stripe.

### Things worth watching on the first run

- **3-D Secure inside the WebView** — the most likely place to need a tweak. The redirect
  fallback exists, but confirm it actually returns to the page on both Windows and Android.
- **Amount match** — the function rejects the payment if Stripe's captured amount differs
  from the recomputed order total. If you hit `amount_mismatch`, the published tax rate and
  the order lines have diverged.
- **Currency** — a mismatch between `STRIPE_CURRENCY` and the account's country is rejected
  rather than silently converted.

---

## Going live

1. Complete Stripe activation (business details + bank account) — the restaurant's own
   entity, not the software vendor's.
2. **Confirm no test-amount override is set.** A sandbox-only override once forced every
   charge to a fixed CA$1.00; it was provider-agnostic, and because the verify step
   compared against the *same* override, nothing ever flagged it. The code no longer reads
   it, but clear the stale secrets anyway so nobody reintroduces the behaviour:
   ```bash
   npx supabase secrets unset PAY_TEST_AMOUNT_CENTS MONERIS_TEST_AMOUNT_CENTS
   ```
   ⚠️ Refund any CA$1.00 test charges *before* removing it — afterwards a refund asks for
   the full order total against a $1.00 PaymentIntent, and Stripe rejects that.
3. Swap the secrets for the `sk_live_…` / `pk_live_…` pair and redeploy.
4. Confirm `?action=diag` reports `mode: "LIVE — real money"`, then run one small real card
   payment **and refund it**.
5. Check the **tip** end to end: place an order with a tip and confirm the Stripe charge is
   `subtotal + tax + tip`, and that the tip appears in the merchant's daily report.

### What the function does with the money — worth knowing before you trust it

- **The tip is charged.** The customer's checkout total is `subtotal + tax + tip`, and that
  is exactly what reaches Stripe. The merchant records the tip separately so it lands in
  the day's tip total rather than vanishing.
- **The service fee is waived online**, on both sides, because the customer is never shown one.
- **Tax fails closed.** If the published tax rate can't be read, the order is refused rather
  than charged without tax.
- **A capture that can't be reconciled is refunded automatically.** If the amount or currency
  disagrees with the server's recomputation *after* the card was captured, the function
  refunds the charge in full and logs `UNRECONCILED CAPTURE`. Without this the customer app
  would treat the order as unpaid and delete it, leaving a customer charged for an order that
  no longer exists. **Grep your function logs for `UNRECONCILED CAPTURE` and
  `MANUAL REFUND REQUIRED`** — the second means the auto-refund itself failed and a human
  must refund it in the Stripe dashboard.
- **Customers never see processor internals.** Raw responses, tokens and error bodies go to
  the function logs; the customer gets a plain sentence.

### Still open (known, deliberate)

- Line prices come from the customer's own insert and are **not** validated against the
  published menu. A forged client could submit a low `priceSnapshot`. Paid-online orders
  auto-accept, so no human reviews it. Validating lines server-side is the next hardening step.
- The tax rate is read live rather than snapshotted onto the order, so a menu republish
  mid-checkout can change the total between the page load and the charge. The auto-refund
  above contains the damage; snapshotting `tax_rate_bp` at insert would remove the race.

For a fleet of restaurants, each restaurant holds its own Stripe account and its own keys —
or is onboarded as a connected account under **Stripe Connect**, which adds a single
`Stripe-Account` header to these same calls. Nothing else in the flow changes.
