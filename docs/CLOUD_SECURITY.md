# Cloud security model

Applies to the optional cloud features (sync, online ordering, and later
online payment). Each restaurant uses **its own Supabase project**; we host
nothing. This document is the authoritative setup — the SQL here is what a
restaurant applies to its project before going live.

> **Status:** verified live (2026-06-13). This model was applied to a real
> Supabase project and the live smoke test
> (`apps/customer/tool/live_cloud_smoke_test.dart`) passed all 15 checks over
> real HTTP. It remains a **per-deployment gate**: each restaurant must apply
> this SQL + auth setup to its own project before enabling cloud features.
> Until then, the apps work fully offline.

## Keys (what's secret, what isn't)

| Key | Where it lives | Notes |
|---|---|---|
| **anon / publishable key** | both apps (merchant + customer) | Safe to embed and share (e.g. via QR). Grants nothing on its own — every table is governed by RLS. |
| **service-role key** | **nowhere in any client** | Bypasses RLS. Only ever used by a trusted backend (a Supabase Edge Function on the restaurant's project, introduced with online payment). Never in app code or the repo. |

The anon key is necessary but **not sufficient** to read anything sensitive —
RLS decides. A table with RLS **disabled** is fully open to the anon key, so RLS
must be enabled on every table below.

## Two trust levels, via Supabase Auth

The same anon key reaches both the restaurant's private data and customers, so
identity — not the key — is what separates them.

- **Merchant tablet** signs in as a real restaurant user (email + password the
  restaurant creates in *Authentication → Users*). Its JWT is `authenticated`
  and **not** anonymous.
- **Customer app** uses **anonymous sign-in** (enable *Authentication →
  Providers → Anonymous*). Each device gets its own `authenticated` JWT flagged
  `is_anonymous = true` and a unique `auth.uid()`.

Every PostgREST request sends `apikey: <anon key>` **and**
`Authorization: Bearer <the signed-in user's access token>`. RLS then sees
`auth.uid()`, `auth.role()`, and `auth.jwt() ->> 'is_anonymous'`.

A row is "the restaurant" when:

```sql
auth.role() = 'authenticated'
  and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false
```

## Tables and policies

```sql
-- ───────────────────────────────────────────────────────────────────────
-- sync_changes : the restaurant's private change feed. Customers: no access.
-- ───────────────────────────────────────────────────────────────────────
create table sync_changes (
  id          uuid primary key,
  entity      text        not null,
  entity_id   text        not null,
  op          text        not null,
  payload     jsonb,
  occurred_at timestamptz not null,
  device_id   text        not null
);
create index sync_changes_occurred_at on sync_changes (occurred_at);

alter table sync_changes enable row level security;
create policy sync_restaurant_all on sync_changes for all
  to authenticated
  using  (coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false)
  with check (coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false);
-- No policy grants anon or anonymous users anything → they are denied.

-- ───────────────────────────────────────────────────────────────────────
-- pos-assets (Storage bucket) : the restaurant's private binary assets that
-- the row feed can't carry — currently the customer-display promo photos
-- (objects promo/<sha>.<ext> + promo/manifest.json). Private, restaurant-only.
-- ───────────────────────────────────────────────────────────────────────
-- Create a NON-public bucket (public=false → no unauthenticated CDN URL).
insert into storage.buckets (id, name, public)
  values ('pos-assets', 'pos-assets', false)
  on conflict (id) do nothing;

-- Objects live in storage.objects; scope every policy to this bucket. Only the
-- signed-in (non-anonymous) restaurant user may read or write; anon/anonymous
-- get nothing (no policy → denied), same trust line as sync_changes.
create policy assets_restaurant_all on storage.objects for all
  to authenticated
  using  (bucket_id = 'pos-assets'
          and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false)
  with check (bucket_id = 'pos-assets'
          and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false);
-- Promo photos are shown on the merchant-side customer display (which reads a
-- local cache), so the bucket needs no public read. If a future customer-app
-- feature must read an asset directly, add a narrow `for select to anon` policy
-- for just that key prefix — never make the whole bucket public.

-- ───────────────────────────────────────────────────────────────────────
-- published_menu : public to read, restaurant to write.
-- ───────────────────────────────────────────────────────────────────────
create table published_menu (
  id           text primary key,
  menu         jsonb not null,
  published_at timestamptz not null default now()
);

alter table published_menu enable row level security;
create policy menu_public_read on published_menu for select
  to anon, authenticated using (true);
create policy menu_restaurant_write on published_menu for all
  to authenticated
  using  (coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false)
  with check (coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false);

-- ───────────────────────────────────────────────────────────────────────
-- online_orders : a customer may submit and track ONLY their own order;
-- the restaurant sees and manages all.
-- ───────────────────────────────────────────────────────────────────────
create table online_orders (
  id                  uuid primary key,
  customer_uid        uuid not null default auth.uid(),  -- the device identity
  customer_name       text not null,
  customer_phone      text,
  lines               jsonb not null,
  requested_pickup_at timestamptz not null,
  submitted_at        timestamptz not null default now(),
  status              text not null default 'submitted',
  note                text,
  is_kiosk            boolean not null default false  -- placed at an in-store kiosk
);
create index online_orders_status on online_orders (status);

alter table online_orders enable row level security;

-- Customer: insert their own, still 'submitted'. customer_uid defaults to
-- auth.uid(); the check makes spoofing another uid impossible.
create policy oo_customer_insert on online_orders for insert
  to authenticated
  with check (customer_uid = auth.uid() and status = 'submitted');

-- Customer: read only their own rows (their status).
create policy oo_customer_read_own on online_orders for select
  to authenticated
  using (customer_uid = auth.uid());

-- Restaurant: read and update everything (accept/reject/ready/picked up).
create policy oo_restaurant_all on online_orders for all
  to authenticated
  using  (coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false)
  with check (coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false);
```

Policies are **OR-combined**: the restaurant matches `oo_restaurant_all`; a
customer matches the two `oo_customer_*` policies. A customer has **no** UPDATE
or DELETE policy, so they cannot change a price or flip a status — only the
restaurant can. And `customer_uid = auth.uid()` means one customer can never
read another's order.

### Customer order updates (pickup-time negotiation + pickup confirmation)

The customer app may update its own order in exactly two situations:

1. **Pickup-time negotiation.** The merchant proposes a new time
   (`status -> 'timeProposed'`, `proposed_pickup_at` set); the customer
   **approves** (back to `submitted` at the agreed time, so the merchant
   accepts it normally) or **declines** (`rejected`).
2. **Pickup confirmation.** A `ready` order can be confirmed collected
   (`ready -> 'pickedUp'`) by either side, so both see it completed.

Those are the customer app's **only** writes besides the original insert. Apply
this once, then re-run `apps/customer/tool/live_cloud_smoke_test.dart`:

```sql
-- New column for the merchant's proposed time.
alter table online_orders add column if not exists proposed_pickup_at timestamptz;

-- Flags an in-store kiosk order so the merchant can auto-accept it straight to
-- the Orders board. Optional: the customer app only sends it for kiosk orders,
-- so shops that haven't added the column still take normal orders fine.
alter table online_orders add column if not exists is_kiosk boolean not null default false;

-- Customer may UPDATE only their own row, only out of 'timeProposed' (respond)
-- or 'ready' (confirm pickup). The exact transitions are pinned by the trigger.
create policy oo_customer_respond on online_orders for update
  to authenticated
  using (customer_uid = auth.uid() and status in ('timeProposed', 'ready'))
  with check (
    customer_uid = auth.uid()
    and status in ('submitted', 'rejected', 'pickedUp')
  );

-- RLS WITH CHECK only sees the NEW row, so it can't tell whether the customer
-- also tampered with price/lines, nor which transition this is. This trigger
-- pins the exact allowed transitions and freezes everything else whenever an
-- anonymous (customer) actor updates.
create or replace function oo_guard_customer_update()
returns trigger language plpgsql as $$
begin
  if coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) then
    if old.status = 'timeProposed' then
      if new.status not in ('submitted', 'rejected') then
        raise exception 'invalid customer status transition';
      end if;
      -- The agreed time may only become the time the restaurant proposed.
      if new.requested_pickup_at is distinct from old.requested_pickup_at
         and new.requested_pickup_at is distinct from old.proposed_pickup_at then
        raise exception 'pickup time must match the proposed time';
      end if;
    elsif old.status = 'ready' then
      if new.status <> 'pickedUp' then
        raise exception 'a ready order may only be marked picked up';
      end if;
      if new.requested_pickup_at is distinct from old.requested_pickup_at then
        raise exception 'pickup time is fixed';
      end if;
    else
      raise exception 'customer may not update this order now';
    end if;
    -- Order contents are immutable for the customer in every case.
    if new.lines        is distinct from old.lines
       or new.id           is distinct from old.id
       or new.customer_uid is distinct from old.customer_uid
       or new.customer_name is distinct from old.customer_name
       or new.customer_phone is distinct from old.customer_phone
       or new.submitted_at is distinct from old.submitted_at then
      raise exception 'customer may not change order contents';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists oo_guard_customer_update on online_orders;
create trigger oo_guard_customer_update
  before update on online_orders
  for each row execute function oo_guard_customer_update();
```

Without this, the Approve/Decline and customer-side "Picked up" buttons return a
permission error (the customer has no UPDATE policy) — which fails safe.

## What this guarantees

- A customer (anonymous) holding the anon key can: read the published menu,
  submit a preorder tied to their own device id, and read their own order's
  status. Nothing else.
- A customer **cannot** read or write `sync_changes`, read other customers'
  orders, change any order's status or price, or read/write the private
  `pos-assets` Storage bucket (promo photos).
- The restaurant (authenticated, non-anonymous) has full access to its data,
  including the `pos-assets` bucket.
- No client holds a key that bypasses RLS.

## Online payment (Phase 7) — forward note

Online payment adds a **Supabase Edge Function** on the restaurant's project as
the trusted backend: it holds the processor's secret key, verifies the charge
with the processor (webhook/API — never the client's word), recomputes the
amount from the order, and is the **only** writer of a `paid` status. Card data
goes customer → processor directly; we never see it. See PRINCIPLES.md (5, 6)
and the Phase 7 entry in ROADMAP.md.
