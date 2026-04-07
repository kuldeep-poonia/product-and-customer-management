# ShopIQ

**Smart business companion for kirana stores and local retailers.**

ShopIQ is a production-ready Flutter mobile app built for small shop owners in India who need to run their daily business from a single smartphone. No counter setup, no training, no complex menus. One app, one phone, full control.

![ShopIQ Dashboard](docs/images/dashboard.png)

---

## Who is this for?

- Kirana store owners running a shop from a smartphone
- Local retailers managing credit customers manually today
- Shop owners who want WhatsApp billing without any separate tools
- Any small business doing 50–500 transactions a day

---

## Core Features

| Feature | What it does |
|---------|-------------|
| Quick Billing | Create and save a bill in under 10 seconds |
| Khata / Udhaar | Track customer credit with payment timeline |
| Inventory | Live stock levels, low stock alerts, expiry warnings |
| WhatsApp Orders | Receive, pack, and dispatch orders from WhatsApp |
| UPI + Cash | Split payment tracking, daily totals, mode breakdown |
| Reports | Daily profit, weekly chart, best sellers, credit risk |
| Hindi + English | Full bilingual UI, switch without restart |
| Offline First | All data local — works without internet |
| Dark Mode | Full dark/light theme, persisted across sessions |
| Settings | Shop name, language, biometric unlock (roadmap) |

---

## Screenshots

| Login | Dashboard | Billing |
|-------|-----------|---------|
| ![Login](docs/images/login.png) | ![Dashboard](docs/images/dashboard.png) | ![Billing](docs/images/billing.png) |

| Khata | Inventory | Reports |
|-------|-----------|---------|
| ![Khata](docs/images/khata.png) | ![Inventory](docs/images/inventory.png) | ![Reports](docs/images/reports.png) |

| Scanner | Hindi Mode |
|---------|------------|
| ![Scanner](docs/images/scanner.png) | ![Hindi](docs/images/hindi_mode.png) |

---

## Architecture

```
lib/
├── main.dart                  Entry point. ProviderScope, theme, router.
├── app/
│   ├── router.dart            GoRouter with auth redirect guard.
│   └── theme.dart             Material 3 light + dark themes.
├── core/
│   ├── app_constants.dart     Brand strings in one place.
│   ├── models.dart            Pure Dart data models.
│   ├── providers.dart         Riverpod StateNotifiers for all app state.
│   ├── widgets.dart           Shared reusable UI components.
│   └── db/
│       └── app_database.dart  Drift/SQLite schema and query helpers.
└── screens/
    ├── auth/                  Login, session restore, auth state.
    ├── dashboard/             Today sales, alerts, quick actions.
    ├── billing/               Cart, discount, payment mode, save.
    ├── khata/                 Customer ledger, payment history.
    ├── inventory/             Stock grid, low stock tab, expiry tab.
    ├── orders/                WhatsApp orders, status pipeline.
    ├── reports/               Profit, weekly chart, best sellers.
    └── settings/              Theme, language, shop info, logout.
```

State management: **Riverpod** (StateNotifier pattern).  
Navigation: **GoRouter** with auth redirect, shell route, deep link support.  
Persistence: **Drift + SQLite** (local, offline-first).  
Theming: **Material 3**, Google Fonts (Noto Sans), full dark mode.

---

## Setup

### Requirements

- Flutter 3.16+ (`flutter --version`)
- Dart 3.1+
- Android SDK 21+ (min API level)

### Run

```bash
git clone https://github.com/your-org/shopiq
cd shopiq
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Build release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Run on physical device (recommended)

Low-to-mid range Android phones respond better than emulators for testing
the real scroll and tap performance target users experience.

```bash
flutter run --release
```

---

## Offline Reliability

All data is stored locally on the device using SQLite via Drift.  
The app works fully without internet except for:

- WhatsApp share (requires WhatsApp installed)
- Phone call dialing (requires cellular)

Data survives: app restart, crash, force close, OS kill, low memory.

See [docs/OFFLINE_SYNC.md](docs/OFFLINE_SYNC.md) for the full strategy.

---

## Security

- Auth tokens stored in `flutter_secure_storage` (hardware-backed keystore on Android)
- No plain SharedPreferences for sensitive values
- Route guard on every protected route — unauthenticated deep links redirect to login
- Audit log table records all critical actions (bill saves, stock edits, logins)
- Request timeout + retry policy on all API calls
- DB encryption hooks ready (SQLCipher extension point in `app_database.dart`)

See [docs/SECURITY.md](docs/SECURITY.md) for the full security model.

---

## Language Support

Two languages supported out of the box:

| | English | Hindi |
|-|---------|-------|
| UI labels | ✓ | ✓ |
| Error messages | ✓ | ✓ |
| WhatsApp messages | ✓ | ✓ |
| Number format | en_IN | en_IN |
| Currency | ₹ | ₹ |

Switch language from **Settings → Language / भाषा**. No restart required.

See [docs/LOCALIZATION.md](docs/LOCALIZATION.md) for adding more languages.

---

## Scanner

The scanner module supports:

- QR Code, EAN-13, EAN-8, Code-128, Code-39, UPC-A, UPC-E, ITF, Data Matrix
- Flashlight toggle
- Vibration feedback on scan
- Duplicate scan debounce (500ms window)
- Fallback manual barcode input
- Product auto-lookup after scan
- Scan history (last 20)

See [docs/SCANNER_TESTING.md](docs/SCANNER_TESTING.md) for validation steps.

---

## Selling Points

- Works on ₹8,000 Android phones — no high-spec device required
- Portrait-only, one-hand operation — shop counter doesn't need landscape
- Bill created in under 10 seconds from cold start
- Khata balance visible in 2 taps from home
- WhatsApp share works without copy-paste — one button sends the full bill
- No cloud subscription required — data stays on device
- Hindi UI for non-English owners
- Dark mode for low-light shop environments

See [docs/SELLING_POINTS.md](docs/SELLING_POINTS.md) for the full pitch deck notes.

---

## Roadmap

- [ ] Cloud sync (Firebase / Supabase option)
- [ ] Biometric unlock (local auth)
- [ ] GST invoice generation with PDF export
- [ ] Multi-shop / employee accounts
- [ ] SMS OTP login
- [ ] Supplier order management
- [ ] Barcode label printing via Bluetooth
- [ ] Tamil, Telugu, Marathi language support
- [ ] iOS build

---

## License

Private / Commercial. Contact the author for licensing.
