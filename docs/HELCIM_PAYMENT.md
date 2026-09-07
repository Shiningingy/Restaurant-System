# Helcim online payment (HelcimPay.js)

The `pay-online` Supabase Edge Function supports **two** processors, selected at
runtime. Helcim is the newer path (self-serve account, no NDA/partner gate);
Moneris stays intact as a fallback. See also `docs/MONERIS_PAYMENT.md`.

- **Provider selection** (`paymentProvider()` in `index.ts`):
  - `HELCIM_API_TOKEN` set → **Helcim**.
  - else → **Moneris**.
  - force either with `PAYMENT_PROVIDER=helcim|moneris`.
- **Vendor wire format** lives in `helcim.ts` (mirrors `moneris.ts`). Card data
  never touches this function — the customer types it only inside Helcim's hosted
  modal, which returns a signed result we validate.
- **Flutter is unchanged.** `PaymentWebView` still just polls
  `online_orders.payment_status == 'paid'`; that seam is vendor-agnostic.

## Flow

1. **GET `?order_id=`** → recompute the amount from the order + published tax →
   `POST https://api.helcim.com/v2/helcim-pay/initialize` (amount fixed here,
   server-side) → `{ checkoutToken, secretToken }`. Stash `secretToken` on the
   order (`pay_secret`) — the function is stateless between GET and the verify
   POST. Serve the HelcimPay.js page.
2. **Browser** loads HelcimPay.js, `appendHelcimPayIframe(checkoutToken)`, the
   customer pays; the modal fires the `helcim-pay-js-<checkoutToken>` message with
   `eventStatus: 'SUCCESS'` and `eventMessage = JSON.stringify({ data, hash })`.
3. **POST `?action=verify` `{ order_id, data, hash }`** → validate the hash =
   `sha256(compactJson(data) + secretToken)` (proves it came from Helcim), confirm
   `data.status === 'APPROVED'` and the amount, then write `payment_status='paid'`,
   `processor_ref = data.transactionId`, and clear `pay_secret`.
4. **POST `?action=refund` `{ order_id }`** (restaurant-authenticated) →
   `POST /v2/payment/refund` with `originalTransactionId = processor_ref`.

## One-time cloud setup (deploy steps)

**1. DDL — add the transient session column** (run in the Supabase SQL editor):

```sql
alter table online_orders add column if not exists pay_secret text;
```

- It holds the HelcimPay `secretToken` only between the GET and the verify POST,
  and is cleared to `null` the moment the order is paid.
- It is written **only** by this function (service role), so the existing
  `oo_guard_customer_update` trigger does **not** need to change — `pay_secret`
  is not a customer-writable column.

**2. Secrets:**

```bash
supabase secrets set HELCIM_API_TOKEN=<your Helcim API token> HELCIM_CURRENCY=CAD
# optional, sandbox only — force a known-approved amount to test wiring end-to-end:
# supabase secrets set PAY_TEST_AMOUNT_CENTS=100
```

Get the API token in the Helcim dashboard: **Settings → Integrations → API
Access → generate a token** (grant it Payment + HelcimPay permissions).

**3. Deploy:**

```bash
supabase functions deploy pay-online --no-verify-jwt
```

To roll back to Moneris, unset `HELCIM_API_TOKEN` (or set `PAYMENT_PROVIDER=moneris`).

## Test checklist (when the Helcim account is ready)

- [ ] `GET ...?order_id=<real unpaid order>&action=diag` returns
      `{ initializeOk: true }` — confirms the API token works.
- [ ] Place a preorder → pay in the modal with a Helcim **test card** → the app
      flips to paid (polling `payment_status`).
- [ ] Confirm the charge amount in the Helcim dashboard matches the order total
      (unset `PAY_TEST_AMOUNT_CENTS` for real amounts).
- [ ] Refund from the merchant inbox → Helcim shows the refund.
- [ ] **Verify against the sandbox** (documented but untested here):
  - the `eventMessage` shape is `{ data, hash }` (adjust the page's
    `resp.data / resp.hash` extraction if Helcim nests it differently);
  - the hash matches (the ASCII-escape in `escapeNonAscii` mirrors Helcim's
    Python `ensure_ascii=True`; only matters if a field has non-ASCII);
  - the refund endpoint/shape (`/v2/payment/refund`, `originalTransactionId`) —
    Helcim documents both an online refund and a device refund.
- [ ] Rendering is clean in the in-app WebView (mobile `InAppWebView` **and**
      Windows WebView2 — the same surfaces the Moneris page already handles).

## Going live

Switching a shop to Helcim means the shop onboards its **merchant account** with
Helcim (currently Moneris). That's a business decision (you + the partner + the
shop); the code above works against a Helcim **test** account first.
