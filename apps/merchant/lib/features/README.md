# Features

Each feature folder follows the same layering (see docs/ARCHITECTURE.md):

```
<feature>/
├── data/           repositories over Drift; row ⇄ entity mapping
├── application/    Riverpod providers/controllers
└── presentation/   screens + widgets
```

Planned features and where their hardware drivers live:

- `menu/` — categories, items, modifier groups (Phase 1)
- `orders/` — dine-in/takeout order taking, edit/void (Phase 1)
- `printing/` — PrintJob queue + templates; `drivers/` is the ONLY place
  printer SDKs may be imported (Phase 2)
- `payments/` — charge/refund flows; `drivers/` is the ONLY place payment
  vendor SDKs may be imported (Phase 3)
- `reports/` — read-only queries (Phase 4)
- `sync/` — SyncBackend backends: noop, supabase (Phase 5)
- `settings/` — printer setup, terminal pairing, sync config
