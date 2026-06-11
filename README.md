# Restaurant System

A point-of-sale system for **very small restaurants**: use the tablet you
already have — no dedicated hardware, no required subscription — and you get
order taking, receipt printing, card-terminal integration, and reports.

**Status: Phase 0 (scaffold).** See [docs/ROADMAP.md](docs/ROADMAP.md).

## What's in the box

| Path | What |
|---|---|
| `packages/domain` | Pure Dart shared package: `Money` (integer cents), `Result`, UUID ids, and the four hardware/cloud abstraction interfaces |
| `apps/merchant` | The POS app (iOS first; Android/Windows capable). Flutter + Riverpod + Drift |
| `apps/customer` | Customer app for online preorder & pickup — Phase 6, placeholder only |
| `docs/` | [PRINCIPLES](docs/PRINCIPLES.md) · [ARCHITECTURE](docs/ARCHITECTURE.md) · [ROADMAP](docs/ROADMAP.md) |

## Principles (the short version)

1. **Offline-first** — the POS works with airplane mode on; SQLite on the tablet is the source of truth.
2. **No required subscription** — optional cloud features run on the restaurant's *own* free-tier Supabase; we host nothing.
3. **Money is integer cents** — `double` never touches currency.
4. **Hardware abstraction** — printers (ESC/POS) and payment terminals (Moneris first) sit behind interfaces with manual/noop fallbacks.
5. **Never touch card data** — semi-integrated terminal in store; processor-hosted checkout if online payment ever ships.

Full text: [docs/PRINCIPLES.md](docs/PRINCIPLES.md)

## Development setup

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable, ≥ 3.44 / Dart ≥ 3.12).
2. From the repo root: `flutter pub get` (single pub workspace — resolves everything).
3. Run the merchant app: `cd apps/merchant && flutter run` (pick a device).
4. Tests: `flutter test` inside `apps/merchant`, `dart test` inside `packages/domain`.

### Platform notes

- **iOS** is the primary target, but iOS builds require a Mac or hosted macOS
  CI (GitHub macOS runners / Codemagic). Daily development works fine on the
  Windows desktop target or an Android emulator.
- Windows desktop builds need Visual Studio with the C++ desktop workload.
- Android builds need the Android SDK (install via Android Studio).

## License

Copyright © 2026 Shiningingy. **All rights reserved.**

This source code is published for reference only. No permission is granted to
use, copy, modify, or distribute this software, in whole or in part, for any
purpose.
