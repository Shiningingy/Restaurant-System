# Roadmap

Phases ship in order; each has a concrete exit criterion. iOS is the first
target platform, with daily development on Android emulator / Windows desktop.

## Phase 0 — Scaffold ✅
Monorepo (shared `packages/domain` + `apps/merchant`), port interfaces,
principles/architecture docs, CI.
**Exit:** CI green on the pushed repo.

## Phase 1 — Core POS
Drift schema and migrations, menu/category/modifier CRUD, dine-in (tables) and
takeout orders, edit/void lines, tax and totals.
**Exit:** take and close an order fully offline.

## Phase 2 — Receipt printing
PrintJob queue with retry, ESC/POS ticket builder, customer-receipt and
kitchen-ticket templates. Network (LAN/TCP 9100) driver first — it works on all
platforms and is easiest to test — then Bluetooth.
**Exit:** an order prints a kitchen ticket and a customer receipt on real hardware.

## Phase 3 — Payment terminal
`ManualEntryTerminal` first (staff keys the amount on a standalone terminal and
records the result — zero vendor dependency), then `MonerisGoTerminal` via the
Moneris Go semi-integrated API. Tips and partial payments.
**Exit:** close an order by pushing the total to a terminal without re-keying.

## Phase 4 — Reports & history
Daily sales summary (Z-report style), order history browser, item sales counts.
All read-only queries over the existing schema.
**Exit:** end-of-day report matches the day's closed orders.

## Phase 5 — Optional cloud sync
SyncLog change journaling, `SupabaseSyncBackend`, settings UI where the
restaurant enters its own Supabase URL + key. Last-write-wins conflict policy,
documented.
**Exit:** a wiped tablet restores its data from the restaurant's Supabase.

## Phase 6 — Customer app & online preorder
Scaffold `apps/customer` (iOS/Android). Menu browsing (published to the
restaurant's Supabase), preorder for **pickup, pay at store** — no online
payment. Merchant app gets an incoming-orders inbox (accept/reject, prep time)
via `OnlineOrderChannel`. Restaurant discovery via QR code / restaurant code.
**Exit:** a phone places a preorder; the tablet accepts it; the customer sees "ready."

## Phase 7 — Optional online payment
Processor-hosted checkout (Moneris Checkout preferred — aligns with the
terminal) behind the existing payment abstraction. We never handle card data.
**Exit:** a preorder can be paid online; refunds work.

## Later / explicitly out of MVP
- Android UX polish, Windows desktop target
- Multi-device (two tablets, one source-of-truth)
- Kitchen display screen (KDS)
- Staff accounts / permissions
