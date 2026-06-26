# Online card payment (Moneris) — setup

Phase 7 lets a customer **pay by card when they preorder** for pickup. It is
**off by default** and entirely optional: without it, preorders are pay-at-counter
exactly as before. You host nothing — payment runs on **your own** Supabase
project and **your own** Moneris account.

## How it works (and what it guarantees)

```
customer app  ──"Pay online"──▶  pay-online Edge Function (your Supabase)
                                   │  preload → Moneris, serve hosted page
   browser  ◀── Moneris hosted checkout page (card entered on Moneris) ──┘
   customer pays on Moneris ▶ function verifies the receipt server-to-server
                              ▶ writes online_orders.payment_status = 'paid'
merchant tablet polls the order ▶ sees 'paid' ▶ records the order as paid online
```

- **Card data goes customer → Moneris directly.** It never touches the customer
  app, the merchant tablet, this function's logs, or your database — only a
  ticket / receipt / transaction id does.
- The function **recomputes the amount from the order** (subtotal + tax, the
  same math the apps use) before trusting any payment, so nobody can pay $0.01
  for a $50 order.
- The function is the **only** writer of `payment_status = 'paid'`. RLS + the
  `oo_guard_customer_update` trigger (see `CLOUD_SECURITY.md`) stop a customer
  from marking their own order paid.
- The service fee (if any) is **waived for online orders**, so the charged
  amount matches what the customer saw at checkout and what the tablet records.

## 1. Apply the schema

Run the Phase-7 block in `docs/CLOUD_SECURITY.md` (adds `payment_status`,
`paid_at`, `processor_ref` to `online_orders` and freezes them against customer
writes). The `alter table … add column if not exists …` lines are safe to
re-run.

## 2. Deploy the function

Requires the [Supabase CLI](https://supabase.com/docs/guides/cli).

```sh
# From the repo root, on your project:
supabase functions deploy pay-online --project-ref <your-ref> --no-verify-jwt
```

`--no-verify-jwt` is required: the customer's browser opens the checkout page
with no token. The function does its **own** auth — refunds require the
restaurant's login, and it only ever writes paid after verifying with Moneris.

## 3. Set your Moneris secrets

From your Moneris account (use the **QA / test store** first):

```sh
supabase secrets set \
  MONERIS_STORE_ID=<your store id> \
  MONERIS_API_TOKEN=<your api token> \
  MONERIS_CHECKOUT_ID=<your Moneris Checkout id> \
  MONERIS_ENV=qa \
  --project-ref <your-ref>
```

Switch `MONERIS_ENV=prod` when you go live. `SUPABASE_URL`,
`SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically —
you don't set those. **Secrets never go in the app or this repo.**

## 4. Turn it on in the POS

Merchant app → **Settings → Online ordering → Accept online payment** (on), then
publish the menu (any menu edit republishes). The customer app now shows
**"Pay online"** at checkout.

## Testing on the QA sandbox

1. Place a preorder in the customer app → tap **Pay online** → the browser opens
   Moneris's hosted page.
2. Pay with a [Moneris test card](https://developer.moneris.com) (QA store).
3. The customer's status screen flips to **"Paid online"**; the merchant tablet
   receives the order **already paid** and auto-accepts it to the board.
4. **Refund:** open the order on the tablet → **Refund** → the charge is reversed
   through Moneris and the order is voided.

> ⚠️ The Moneris request/response field names in `pay-online/moneris.ts` follow
> the Moneris Checkout Integration Guide; confirm them against your QA sandbox
> before going live. They're isolated in that one file.
