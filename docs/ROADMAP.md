# Roadmap

Phases ship in order; each has a concrete exit criterion. iOS is the first
target platform, with daily development on Android emulator / Windows desktop.

## Phase 0 — Scaffold ✅
Monorepo (shared `packages/domain` + `apps/merchant`), port interfaces,
principles/architecture docs, CI.
**Exit:** CI green on the pushed repo.

## Phase 1 — Core POS ✅
Drift schema and migrations, menu/category/modifier CRUD, dine-in (tables) and
takeout orders, edit/void lines, tax and totals.
**Exit:** take and close an order fully offline.

## Phase 2 — Receipt printing
PrintJob queue with retry, ESC/POS ticket builder, customer-receipt and
kitchen-ticket templates. Network (LAN/TCP 9100) driver first — it works on all
platforms and is easiest to test — then Bluetooth.
**Exit:** an order prints a kitchen ticket and a customer receipt on real hardware.
*Status: code complete (queue, templates, encoder, network driver, settings UI);
awaiting a real LAN printer for the hardware exit check. Bluetooth driver follows
once a mobile test device is available.*

## Phase 3 — Payment terminal
`ManualEntryTerminal` first (staff keys the amount on a standalone terminal and
records the result — zero vendor dependency), then `MonerisGoTerminal` via the
Moneris Go semi-integrated API. Tips and partial payments.
**Exit:** close an order by pushing the total to a terminal without re-keying.
*Status: manual-entry flow complete — payment sheet with tips and split/partial
payments, every outcome recorded (declines kept for audit), order auto-closes at
zero balance, receipts list all payments. `MonerisGoTerminal` is blocked on the
"Moneris Go Cloud 3.0 – API Specification": it is not public; Moneris' Client
Consulting team provides it (with a QA terminal, test cards, and API token)
once you register as an integrator — see the
[integration guide](https://www.moneris.com/-/media/files/devices/moneris-go/moneris-go-integration-guide.ashx).*

## Phase 4 — Reports & history
Daily sales summary (Z-report style), order history browser, item sales counts.
All read-only queries over the existing schema.
**Exit:** end-of-day report matches the day's closed orders.
*Status: complete — Reports tab with per-day Z-report (orders/gross/tax/tips,
collected-by-method drawer breakdown, item sales) and a history browser with
order detail + receipt reprint. The exit criterion is pinned by a repository
test (yesterday's orders, open orders and declined payments all excluded).*

## Phase 5 — Optional cloud sync
SyncLog change journaling, `SupabaseSyncBackend`, settings UI where the
restaurant enters its own Supabase URL + key. Last-write-wins conflict policy,
documented.
**Exit:** a wiped tablet restores its data from the restaurant's Supabase.
*Status: complete — always-on change-feed journaling (in-transaction), pull-
then-push `SyncService` with last-write-wins, `SupabaseSyncBackend` over a
single PostgREST `sync_changes` table, and a Settings cloud-sync section
(credentials, Sync now, Restore from cloud). The exit criterion is pinned by a
two-database test: device A does business and pushes; an empty device B
restores and reconstructs A's menu, tables, orders, lines, payments and daily
report. The real Supabase adapter is compile-verified only — it needs a live
project to exercise end-to-end (like the LAN printer and Moneris terminal).*

## Phase 6 — Customer app & online preorder
Scaffold `apps/customer` (iOS/Android). Menu browsing (published to the
restaurant's Supabase), preorder for **pickup, pay at store** — no online
payment. Merchant app gets an incoming-orders inbox (accept/reject, prep time)
via `OnlineOrderChannel`. Restaurant discovery via QR code / restaurant code.
**Exit:** a phone places a preorder; the tablet accepts it; the customer sees "ready."
*Status: complete. Shared wire model in `packages/domain`
(`PublishedMenu`/`PreorderSubmission`). Merchant: `SupabaseOnlineOrderChannel`
(+ Noop), `MenuPublisher`, `InboxService` (accept → local `type=online` order),
and an Inbox tab. Customer app: connect to a storefront, browse, cart with
modifiers, place a preorder, live status. Both Supabase clients are tested over
real HTTP against an emulated PostgREST, covering submit → accept → ready end to
end. Discovery is currently paste-the-URL+key; QR scanning is a follow-up. Like
sync, a smoke test against a live Supabase project still needs the restaurant's
real credentials.*

## Pre-deployment gate (cloud security) ✅ CLOSED
Before any real restaurant uses cloud sync or online ordering, harden the
Supabase setup. Today both apps share one project + anon key with no real RLS
(placeholder `using(true)` in the sync setup SQL; none for online orders), so
the customer-facing key could read/modify the restaurant's entire private data
(menu, sales, payments, other customers' details). Required: proper per-table
RLS; `published_menu` anon read-only; `online_orders` anon insert-only with
own-status reads via anonymous auth or a `security definer` RPC; `sync_changes`
denied to the customer key (merchant tablet authenticates instead of using the
shared anon key). Pair with the live-Supabase smoke test. **The full model and
exact SQL are in docs/CLOUD_SECURITY.md.**
**Exit:** the customer key cannot reach `sync_changes` or other customers' orders.
*Status: **closed (2026-06-13).** The client side: the merchant signs in with a
password and the customer signs in anonymously; both carry their user token on
every request, the customer tags preorders with its uid. Then verified **live
against a real Supabase project**: the RLS SQL from CLOUD_SECURITY.md was
applied, a restaurant login created, anonymous sign-ins enabled, and the live
smoke test (`apps/customer/tool/live_cloud_smoke_test.dart`) passed all 15
checks over real HTTP — restaurant writes its private feed/menu, a customer
orders and tracks only their own, and a customer is provably blocked from the
sync feed, other customers' orders, status changes, and uid-spoofing. Re-run any
time against a project with `dart run tool/live_cloud_smoke_test.dart` (creds via
env vars).*

## Phase 7 — Optional online payment
Processor-hosted checkout (Moneris Checkout preferred — aligns with the
terminal) behind the existing payment abstraction. We never handle card data.
**Exit:** a preorder can be paid online; refunds work.

**Security model (design before building):**
- Card data goes straight from customer → processor (hosted checkout, or a
  wallet like Google/Apple Pay that tokenizes the card). We only ever see a
  token or a result, never the PAN. Wallets are payment *methods* — they still
  need a processor/gateway behind them to charge.
- **Never trust the client.** A "paid" status is only accepted when a trusted
  backend confirms it with the processor — not when the customer app or merchant
  tablet says so. Confirmation is via the processor's webhook or an API check.
- Because we host no server, that trusted backend is a **Supabase Edge Function**
  on the restaurant's own project: it holds the processor's *secret* key,
  verifies the charge, recomputes the amount from the order (so nobody pays
  $0.01 for a $50 order), and is the *only* writer of `paid` on an order. Secret
  keys never ship in the customer or merchant app.
- Depends on the cloud-security gate above (RLS + auth) being done first.

## Later / explicitly out of MVP
- Android UX polish, Windows desktop target
- Multi-device (two tablets, one source-of-truth)
- Kitchen display screen (KDS)
- Staff accounts / permissions
