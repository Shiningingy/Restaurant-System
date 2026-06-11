# Architecture

## Monorepo layout

```
packages/domain      Pure Dart. Entities, Money, Result, and the four port
                     interfaces. No Flutter imports allowed — both apps and
                     future tooling depend on it.
apps/merchant        The POS (iOS first; Android/Windows capable). All
                     hardware drivers live here.
apps/customer        Phase 6. Menu browsing + preorder for pickup.
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
PrintJob        id, orderId?, kind{customerReceipt|kitchenTicket}, payload,
                status{queued|printed|failed}, attempts, createdAt
SyncLog         id, entity, entityId, op{insert|update|delete}, payload, syncedAt?
```

### Invariants

- **Snapshots:** order lines copy item name and price at sale time. Editing the
  menu never rewrites history.
- **Voids are status flips,** never row deletes — audit trail and sync safety.
- **All money columns are integer cents** (`int`). See PRINCIPLES.md.
- **IDs are UUIDv4 generated on-device,** never autoincrement — offline-first
  and sync-safe.
- Reports are pure queries over this schema; no derived tables in MVP.

## Online ordering data flow (Phase 6)

```
customer app ──write preorder──▶ restaurant's Supabase ◀──realtime watch── merchant tablet
customer app ◀──order status──── restaurant's Supabase ◀──publish menu/status── merchant tablet
```

The tablet remains the source of truth: an accepted preorder becomes a normal
local `Order` (type=online) and flows through printing/payment/reports like any
other. No Supabase configured → `NoopOnlineOrderChannel` → POS unaffected.

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
