# Restaurant System

A point-of-sale system for **very small restaurants**: use the tablet or PC you
already have — no dedicated hardware, no required subscription — and you get
order taking, receipt printing, card payments, split bills, online preorders,
and reports.

**Status: MVP complete** (offline POS + optional cloud sync + online ordering).
See [docs/ROADMAP.md](docs/ROADMAP.md) for what's done and next.

**Using the app?** See the plain-language **[User Guide](docs/USER_GUIDE.md)**
([中文](docs/USER_GUIDE.zh.md)) — setup, daily POS, payments, online orders.

## What's in the box

| Path | What |
|---|---|
| `packages/domain` | Pure Dart shared package: `Money` (integer cents), `Result`, UUID ids, and the four hardware/cloud abstraction interfaces |
| `apps/merchant` | The POS app (Windows desktop + Android; iOS-capable). Flutter + Riverpod + Drift |
| `apps/customer` | Customer app for online preorder & pickup — built (wallet, QR connect, preorder, status) |
| `docs/` | [USER GUIDE](docs/USER_GUIDE.md) · [PRINCIPLES](docs/PRINCIPLES.md) · [ARCHITECTURE](docs/ARCHITECTURE.md) · [ROADMAP](docs/ROADMAP.md) · [CLOUD SECURITY](docs/CLOUD_SECURITY.md) |

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

- **Windows desktop** (Windows **10/11** only — not 7/8) and **Android** are the
  primary deployment targets. Windows builds need Visual Studio with the C++
  desktop workload, plus **Windows Developer Mode** enabled
  (`start ms-settings:developers`) — Flutter plugins are wired up via symlinks.
- **Android** builds need the Android SDK (install via Android Studio).
- **iOS** is supported but requires a Mac or hosted macOS CI (GitHub macOS
  runners / Codemagic) to build.
- **Linux** desktop is buildable (core POS works); on-device menu-photo OCR is
  Windows/Android-only. Must be built on a Linux host.

## License

Copyright © 2026 Shiningingy. **All rights reserved.**

This source code is published for reference only. No permission is granted to
use, copy, modify, or distribute this software, in whole or in part, for any
purpose.
