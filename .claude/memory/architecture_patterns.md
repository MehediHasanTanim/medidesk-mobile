---
name: Offline-First Architecture Patterns
description: Mandatory patterns for every new mutable entity in MediDesk
type: project
---

## New Entity Checklist (from ARCHITECTURE.md)

Every new mutable table MUST have these columns:
- `server_id`, `sync_status`, `is_deleted`, `deleted_at`, `last_modified`

Every new feature MUST satisfy all of the following before it's "done":
- [ ] DAO read methods return `Stream<...>` (never `Future<List>`)
- [ ] Repository writes to Drift **before** enqueuing to `SyncQueue`
- [ ] `SyncQueueProcessor._entityPath()` handles the new `entityType`
- [ ] `SyncQueueProcessor._getServerId()` handles the new entity
- [ ] `SyncQueueProcessor._updateServerId()` handles the new entity
- [ ] `PullSyncHandler` has a `_pullX()` method for the new entity
- [ ] `AppDatabase.wipeAll()` includes `delete(newTable).go()`
- [ ] `AppDatabase._createIndexes()` registers FK-query indexes
- [ ] Soft-delete filter `isDeleted == 0` applied in EVERY DAO query

## Directory Structure Pattern

```
features/<name>/
  data/
    mappers/   <name>_mapper.dart
    models/    <name>_model.dart  (+ .freezed.dart, .g.dart)
  presentation/
    screens/
```

Use `features/patients/` as the canonical reference for a complete offline-first slice.

## Invoice Total Computation (UI layer only — NOT stored)

```
subtotal = sum(quantity × unit_price)   // non-deleted items
total    = subtotal × (1 - discount_percent / 100)
paid     = sum(amount)                  // non-deleted payments
balance  = total - paid
```

## Soft-delete Contract

- Never hard-delete. Always set `is_deleted = true`, `deleted_at = <timestamp>`.
- Server returns deleted records in delta pulls with `"is_deleted": true`.
- Every DAO query MUST filter `WHERE is_deleted = 0`.
