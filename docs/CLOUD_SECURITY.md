# Cloud security model

Applies to the optional cloud features (sync, online ordering, and later
online payment). Each restaurant uses **its own Supabase project**; we host
nothing. This document is the authoritative setup — the SQL here is what a
restaurant applies to its project before going live.

> **Status:** this is the target model. It is a **blocking pre-deployment gate**
> (see ROADMAP.md): do not enable cloud features for a real restaurant until the
> RLS and auth here are in place. Until then, the apps work fully offline.

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
  note                text
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

## What this guarantees

- A customer (anonymous) holding the anon key can: read the published menu,
  submit a preorder tied to their own device id, and read their own order's
  status. Nothing else.
- A customer **cannot** read or write `sync_changes`, read other customers'
  orders, or change any order's status or price.
- The restaurant (authenticated, non-anonymous) has full access to its data.
- No client holds a key that bypasses RLS.

## Online payment (Phase 7) — forward note

Online payment adds a **Supabase Edge Function** on the restaurant's project as
the trusted backend: it holds the processor's secret key, verifies the charge
with the processor (webhook/API — never the client's word), recomputes the
amount from the order, and is the **only** writer of a `paid` status. Card data
goes customer → processor directly; we never see it. See PRINCIPLES.md (5, 6)
and the Phase 7 entry in ROADMAP.md.
