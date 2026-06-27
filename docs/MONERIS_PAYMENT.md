# Online card payment (Moneris) — setup

Phase 7 lets a customer **pay by card when they preorder** for pickup. It is
**off by default** and entirely optional: without it, preorders are pay-at-counter
exactly as before. You host nothing — payment runs on **your own** Supabase
project and **your own** Moneris account.

## How it works (and what it guarantees)

```
customer app  ──"Pay online"──▶  pay-online Edge Function (your Supabase)
                                   │  serves a page with Moneris's Hosted
                                   │  Tokenization iframe (card field)
   browser ── card entered in Moneris's iframe ─▶ Moneris returns a token
   page POSTs the token ▶ function charges it (POST /payments, X-Api-Key)
                        ▶ writes online_orders.payment_status = 'paid'
merchant tablet polls the order ▶ sees 'paid' ▶ records the order as paid online
```

This uses the **new Moneris API** (`api.moneris.io`) + **Hosted Tokenization**:
the customer types their card into a Moneris-controlled iframe, which returns a
temporary token; the function charges that token with `paymentMethodSource:
TEMPORARY_TOKEN`. Auth is your **Subscriptions API key** (`X-Api-Key`) with the
**Payment** + **Refund** scopes.

- **Card data goes customer → Moneris directly.** It never touches the customer
  app, the merchant tablet, this function's logs, or your database — only a
  temporary token / paymentId does.
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

Hosted Tokenization is a **classic Moneris Gateway** product, so the charge uses
the classic **`store_id` + `api_token`** — for the **same store that owns your HT
profile**. Find them in the Merchant Resource Center (sandbox first) under
**Admin → Store Settings / API Token**. These are *not* the new-API key or OAuth2
client (those can't charge an HT token — the new REST `/payments` endpoint
returns a blank 500 for it).

```sh
supabase secrets set \
  MONERIS_STORE_ID=<classic store_id, e.g. monca00392> \
  MONERIS_API_TOKEN=<classic api_token for that store> \
  MONERIS_HT_PROFILE_ID=<your Hosted Tokenization profile id> \
  MONERIS_ENV=qa \
  --project-ref <your-ref>
```

`MONERIS_CRYPT_TYPE` is optional (defaults to `7`); set it only if Moneris asks
you to use a different value. Switch `MONERIS_ENV=prod` when you go live.
`SUPABASE_URL`,
`SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically —
you don't set those. **Secrets never go in the app or this repo.**

> The **HT Profile ID** is created in the Merchant Resource Center → Hosted
> Tokenization / Hosted Solutions Configuration. The **sandbox has its own MRC**,
> so you can create an HT profile there and test the full card-entry frame →
> token → charge flow without onboarding a live store. The profile's store is the
> one whose `store_id`/`api_token` you set above.

## 4. Turn it on in the POS

Merchant app → **Settings → Online ordering → Accept online payment** (on), then
publish the menu (any menu edit republishes). The customer app now shows
**"Pay online"** at checkout.

## Testing

**Now (developer sandbox) — the charge/refund API.** Hosted Tokenization needs a
real store (above), so validate the server side with the script:

```sh
# Set the same Moneris values as env vars, then:
node tools/moneris-sandbox-check.mjs
```

It gets a token (API key or OAuth2), does a **Purchase** with a Moneris **test
card**, then a **Refund** — proving your credentials, host, and the request
shapes work. See the script header for the env vars + test card numbers.

**Later (real store) — the full hosted flow.** Once you've onboarded a store and
created the HT profile:
1. Customer app → **Pay online** → the browser opens the page with Moneris's card
   iframe → pay with a test card.
2. Status screen flips to **"Paid online"**; the merchant tablet receives the
   order **already paid** and auto-accepts it.
3. **Refund:** open the order on the tablet → **Refund** → reversed via Moneris,
   order voided.

> ⚠️ The Moneris request/response field names in `pay-online/moneris.ts` follow
> the new Moneris API docs (`developer.moneris.com/moneris-api`); confirm them
> against your sandbox before going live. They're isolated in that one file.
