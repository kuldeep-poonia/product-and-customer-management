# ShopIQ — Offline Strategy

## What Works Offline

Everything. ShopIQ stores all data on-device.

- Create bills
- Add and update stock
- Record khata payments
- View all reports
- Manage orders
- Change settings

No network request is made during any of these operations.

## What Requires Network

- WhatsApp share (requires WhatsApp installed, no internet needed)
- Phone calls (requires cellular signal)
- Future: cloud backup sync (not implemented yet)

## Data Durability

Drift/SQLite provides ACID guarantees.
Every multi-table write uses a transaction.
A process kill mid-write rolls back cleanly — no partial data is left.

## Conflict Resolution (when cloud sync is added)

Strategy: last-write-wins per record using the `createdAt` timestamp.
Bills are append-only — they are never updated after save, only voided.
Stock updates are event-sourced via the audit log so conflicts can be replayed.

## Storage Usage

Typical usage for a shop doing 100 bills/day over one year:
- Bills table: ~4MB
- Bill items: ~12MB
- Khata entries: ~2MB
- Products: ~200KB

Total: well under 20MB for a full year of data.
