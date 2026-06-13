# Architecture

## Monorepo layout

```
packages/domain      Pure Dart. Entities, Money, Result, and the four port
                     interfaces. No Flutter imports allowed — both apps and
                     future tooling depend on it.
apps/merchant        The POS (iOS first; Android/Windows capable). All
                     hardware drivers live here.
apps/customer        Menu browsing + preorder for pickup (Phase 6). Talks to
                     the restaurant's Supabase storefront; depends on domain.
```

Dependency resolution is a single pub workspace (root `pubspec.yaml`).

## Layering rule

Within each feature folder: `presentation → application → data → domain/core`.

- `presentation/` — widgets, screens; no business logic.
- `application/` — Riverpod providers/controllers; orchestrates use cases.
- `data/` — repositories over Drift; maps rows ⇄ entities.
- Features never import each other's internals. Cross-feature access goes
  through interfaces in `packages/domain`, resolved via Riverpod providers.

## The four ports (hardware/cloud abstraction)

| Port | Default impl | Real impls |
|---|---|---|
| `PrinterDriver` | — (every driver has noop/test fallback) | ESC/POS network (all platforms), ESC/POS Bluetooth (mobile) |
| `PaymentTerminal` | `ManualEntryTerminal` | `MonerisGoTerminal` |
| `SyncBackend` | `NoopSyncBackend` | `SupabaseSyncBackend` |
| `OnlineOrderChannel` | `NoopOnlineOrderChannel` | `SupabaseOnlineOrderChannel` |

Vendor SDKs may only be imported inside `features/printing/drivers/` and
`features/payments/drivers/`. Each port is bound through a Riverpod provider
selected by settings, so swapping hardware is configuration, not code change.
Every port has a fake in `test/`.

## Domain model (seeds the Phase 1 Drift schema)

```
Category        id, name, sortOrder, isActive
MenuItem        id, categoryId→Category, name, priceCents, sku?, isActive, sortOrder
ModifierGroup   id, name, minSelect, maxSelect            ("Size", "Add-ons")
Modifier        id, groupId→ModifierGroup, name, priceDeltaCents
MenuItemModifierGroup   itemId ⇄ groupId                  (many-to-many)

DiningTable     id, label, isActive
Order           id, type{dineIn|takeout|online}, tableId?, status{open|sent|paid|voided},
                createdAt, closedAt?, subtotalCents, taxCents, totalCents, note?
OrderLine       id, orderId→Order, menuItemId→MenuItem, nameSnapshot,
                priceCentsSnapshot, qty, lineTotalCents, status{active|voided}, note?
OrderLineModifier  id, lineId→OrderLine, nameSnapshot, priceDeltaCentsSnapshot

Payment         id, orderId→Order, method{terminal|manual|cash}, amountCents,
                tipCents, status{pending|approved|declined|reversed},
                terminalRef?, createdAt
PrintJob        id, orderId?, kind{customerReceipt|kitchenTicket|testPage},
                payload (rendered ESC/POS bytes), attempts, lastError?,
                status{queued|printing|done|failed}, createdAt, updatedAt
SyncLog         id, entity, entityId, op{update|delete}, payload (full-row
                JSON, null for delete), occurredAtUs (int µs since epoch),
                syncedAt?
```

### Invariants

- **Snapshots:** order lines copy item name and price at sale time. Editing the
  menu never rewrites history.
- **Voids are status flips,** never row deletes — audit trail and sync safety.
- **Orders may be settled by several payments** (split bill / partial card
  then cash). Only `approved` payments count toward the balance; declined
  attempts are kept for audit. The order closes when the balance hits zero
  (`PaymentRepository.recordApproved`, one transaction). Tips never reduce
  the balance.
- **All money columns are integer cents** (`int`). See PRINCIPLES.md.
- **IDs are UUIDv4 generated on-device,** never autoincrement — offline-first
  and sync-safe.
- Reports are pure queries over this schema; no derived tables in MVP.

## Optional cloud sync (Phase 5)

Sync is off by default and the POS is fully functional without it forever.
When a restaurant enters its own Supabase URL + anon key, the app
journals and syncs an **append-only change feed**:

- **Journaling.** Every local write to a synced entity also writes a
  `SyncLog` row in the *same transaction* (always on, via `SyncJournal`),
  so the feed can never miss a mutation. Entities are self-contained
  aggregates: `menu_item` carries its modifier-group ids; `order` carries
  its lines and line modifiers. Seven entities sync — categories, menu
  items, modifier groups, modifiers, dining tables, orders, payments.
  Print jobs are device-local and never sync. `SyncCodec` is the single
  source of truth for the wire format (encode-on-journal,
  apply-on-pull).
- **Cycle.** `SyncService` does pull-then-push: pull applies remote
  changes via `SyncCodec` (never re-journaled, so they don't echo back),
  push sends locally-journaled changes the cloud hasn't seen.
- **Conflicts: last-write-wins by `occurred_at`.** Each device stamps
  changes from a per-device monotonic microsecond clock. On pull, a
  remote change is skipped only if this device has a *newer un-pushed*
  change for the same row; otherwise it is applied as a full-row upsert
  (or delete). Replaying the whole feed in timestamp order reconstructs
  the final state — that is exactly **restore on a wiped/new tablet**
  (the Phase 5 exit criterion).
- **Backend.** `SupabaseSyncBackend` (the only place that knows the
  Supabase wire format) is a thin `package:http` adapter over one
  PostgREST table the restaurant creates once:

  ```sql
  create table sync_changes (
    id uuid primary key, entity text not null, entity_id text not null,
    op text not null, payload jsonb,
    occurred_at timestamptz not null, device_id text not null);
  create index sync_changes_occurred_at on sync_changes (occurred_at);
  ```

  Push is an upsert-by-id (idempotent re-push); pull selects
  `occurred_at > cursor and device_id <> self`. No credentials →
  `NoopSyncBackend` → POS unaffected.
- **Scope.** Sync covers database-backed business data. Device settings
  (printer IP, business name, tax rate — in `shared_preferences`) are
  network/store-local and re-entered on a new device, not synced.

## Online ordering data flow (Phase 6)

```
customer app ──write preorder──▶ restaurant's Supabase ◀──realtime watch── merchant tablet
customer app ◀──order status──── restaurant's Supabase ◀──publish menu/status── merchant tablet
```

The tablet remains the source of truth: an accepted preorder becomes a normal
local `Order` (type=online) and flows through printing/payment/reports like any
other. No Supabase configured → `NoopOnlineOrderChannel` → POS unaffected.

Two PostgREST tables in the restaurant's Supabase carry it: `published_menu`
(one row the merchant upserts via `MenuPublisher`, the customer reads) and
`online_orders` (customer inserts `status=submitted`; the merchant polls,
accepts/rejects, and patches `status` accepted→ready→pickedUp; the customer
polls its row). Wire shapes (`PublishedMenu`, `PreorderSubmission`) live in
`packages/domain` so both apps serialize identically; the HTTP transport is a
driver in each app (`SupabaseOnlineOrderChannel` merchant-side,
`SupabaseStorefront` customer-side). Preorders are pay-at-pickup — no payment
data crosses this channel.

## Platform caveats

- **Bluetooth ESC/POS plugins are mobile-only.** LAN/TCP-9100 printing works on
  every platform — the recommended printer story for any future Windows install
  is a network thermal printer. The `PrinterDriver` abstraction makes this a
  configuration choice.
- Drift (+ `sqlite3_flutter_libs`) and `supabase_flutter` work on iOS, Android,
  and Windows. Moneris Go is a cloud HTTP API — platform-neutral.
- Dev machine is Windows: daily iteration on the Android emulator or Windows
  desktop target; **iOS builds require a Mac or hosted macOS CI** (GitHub
  macOS runners / Codemagic).
