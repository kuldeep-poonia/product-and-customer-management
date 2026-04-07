# ShopIQ — Security

## Token Storage

Auth tokens are stored using `flutter_secure_storage`.
On Android this uses the Android Keystore system backed by hardware security.
Tokens are never written to SharedPreferences or plain files.

## Route Guards

All routes except `/login` are protected by a GoRouter redirect.
The redirect reads `authProvider.status` on every navigation event.
An expired or missing token redirects to `/login` before the screen renders.

## Request Policy (when API is wired)

- All HTTP requests go through a single Dio instance with an interceptor
- Access token is attached in the Authorization header
- On 401 response: interceptor attempts token refresh once
- On refresh failure: `AuthNotifier.logout()` is called, user lands on `/login`
- Request timeout: 15 seconds connect + 30 seconds receive
- Retry policy: 2 retries with exponential backoff for network errors (5xx, timeout)
- No retry on 4xx — those are client errors, retrying is pointless

## Audit Log

Every critical action is written to the `audit_log` table with a timestamp.
Critical actions include: bill saved, stock updated, customer deleted, login, logout.
This table is append-only — no UI deletes entries from it.

## Failed Login Throttle

After 5 failed login attempts in 10 minutes, the login form locks for 5 minutes.
This is enforced client-side as a first line of defence.
Server-side rate limiting should mirror this policy.

## Database Encryption

The DB is currently unencrypted SQLite.
To enable encryption: replace `NativeDatabase` in `_openConnection()` with
`NativeDatabase.createInBackground(file, setup: ...)` using SQLCipher.
The hook is already in place — only the setup function needs to change.

## What is NOT secured (known gaps)

- No certificate pinning — add if the app connects to a fixed backend
- No jailbreak/root detection — acceptable for kirana store use case
- Biometric unlock is stubbed, not implemented yet
