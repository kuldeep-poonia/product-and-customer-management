# ShopIQ — Architecture

## Overview

ShopIQ follows a layered architecture inside a single Flutter package.
No over-engineered monorepo, no separate packages for a single-developer project.
The structure is feature-grouped under `screens/` with shared code in `core/`.

## Layer Map

```
UI (screens/)
    ↓ reads/writes
State (Riverpod providers in core/providers.dart)
    ↓ reads/writes
Persistence (Drift/SQLite in core/db/app_database.dart)
    ↓
Local SQLite file (shopiq.db in app documents directory)
```

## State Management

Riverpod `StateNotifier` for all mutable state.

Each notifier owns one slice of state:
- `ProductsNotifier` — product list + stock operations
- `BillingNotifier` — active cart items
- `BillsNotifier` — saved bills + today's aggregates
- `CustomersNotifier` — customer list + khata entries
- `OrdersNotifier` — order list + status updates
- `AuthNotifier` — auth status, session restore, login/logout

Providers are registered at the top level in `providers.dart`.
No code generation required for providers (plain `StateNotifierProvider`).

## Navigation

GoRouter with a `ShellRoute` wrapping all main tabs.

The router is itself a Riverpod provider (`routerProvider`) so it watches
`authProvider` and fires redirects automatically when auth state changes.
This means logout always redirects to `/login` with no manual `context.go()` calls.

Bottom nav derives its selected index from the active route location string,
not from a separate `int _currentIndex` state variable.
This keeps nav correct on deep links, app restore, and back navigation.

## Persistence

Drift generates type-safe query code from the table definitions in `app_database.dart`.
Run `dart run build_runner build` to regenerate after schema changes.

All write operations that touch multiple tables use Drift transactions.
Example: saving a bill writes to `bills` and `bill_items` in one transaction,
so a crash mid-write never leaves orphaned line items.

The database file lives in the app documents directory as `shopiq.db`.
It survives app updates. Clear app data in Android settings to wipe it.

## Security

Tokens go in `flutter_secure_storage`, which uses Android Keystore on Android.
SharedPreferences is used only for non-sensitive settings (theme, language).
Every critical user action is written to the `audit_log` table.

## Adding a New Feature

1. Create `lib/screens/your_feature/your_feature_screen.dart`
2. Add any new state to `lib/core/providers.dart`
3. Add new DB tables to `lib/core/db/app_database.dart` and regenerate
4. Register the route in `lib/app/router.dart`
5. Add bottom nav item in the `AppShell` if it's a top-level tab
