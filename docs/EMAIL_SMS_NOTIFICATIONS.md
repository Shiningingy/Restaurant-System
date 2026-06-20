# Email / SMS "order ready" notifications (optional)

The customer app can mark, per device, that they want to be told **by email
and/or SMS** when their pickup order is ready (Profile → "Notify me when my
order is ready"). The app itself **never sends** these — sending is done by a
small **Supabase Edge Function** that the restaurant deploys on **its own**
project with **its own** provider key. Consistent with the project's
host-nothing principle: we hold no keys and send nothing on anyone's behalf.

On-device notifications (a banner while the app is open) need none of this and
work out of the box. This doc is only for email/SMS, which leave the device.

## What it costs (the restaurant pays, not us or the customer)

- **Email** is effectively free for a restaurant: Resend (3,000/mo free),
  SendGrid (100/day free), or Amazon SES ($0.10 per 1,000). Start here.
- **SMS** always costs money: ~$1/mo for a number + ~US$0.0075 per text
  (Canada). Optional; leave it off and only email is used.

## One-time setup

### 1. Add the columns the order carries

The customer app already sends these on each order; add them once:

```sql
alter table online_orders add column if not exists customer_email text;
alter table online_orders add column if not exists notify_by_email boolean not null default false;
alter table online_orders add column if not exists notify_by_sms   boolean not null default false;
```

(The existing customer-insert RLS policy already allows the customer to write
their own row, so no policy change is needed for these.)

### 2. Deploy the function

```bash
supabase functions deploy notify-order --project-ref <your-ref>
```

The function lives at [`supabase/functions/notify-order/index.ts`](../supabase/functions/notify-order/index.ts).

### 3. Set the provider secret(s)

Email (Resend — recommended first):

```bash
supabase secrets set RESEND_API_KEY=re_xxx NOTIFY_FROM_EMAIL="orders@yourdomain.com"
```

SMS (Twilio — optional, costs money):

```bash
supabase secrets set TWILIO_ACCOUNT_SID=ACxxx TWILIO_AUTH_TOKEN=xxx TWILIO_FROM="+1xxxxxxxxxx"
```

Each channel is independent: if only the email secrets are set, only email is
sent; SMS is skipped silently.

### 4. Fire it when an order becomes ready

Add a **Database Webhook** (Dashboard → Database → Webhooks):

- Table: `online_orders`
- Events: **Update**
- Type: **Supabase Edge Function** → `notify-order`

The function POSTs `{ record, old_record }`; it only sends when the status
**changes into** `ready` (so it fires exactly once), and only for the channels
the customer opted into and that have a configured key.

## Security notes

- The function uses **provider** keys (Resend/Twilio), never the Supabase
  service-role key, and never touches payment data (pickup is pay-at-store).
- Not deploying the function (or leaving the secrets unset) simply means no
  email/SMS is ever sent — the in-app notification still works. Fails safe.
