# Offline-First Architecture

→ [Back to docs](../README.md)

MediDesk is built for clinics with unreliable internet. The device is the source of truth for in-progress work; the server is authoritative only after sync completes.

---

## Core Invariants

These rules apply to **every** mutable entity. Violating any one of them breaks offline sync.

### 1. Write local first

```
User action → Drift (local write) → SyncQueue entry → background push to server
```

Never write to the API before writing to Drift. The app must remain fully functional with no network.

### 2. Read via Stream

All DAO read methods return `Stream<List<...>>`, never `Future<List<...>>`. This keeps the UI reactive to local writes and incoming pull-sync updates.

### 3. Soft-delete everywhere

Never `DELETE` a row. Set `is_deleted = 1` and `deleted_at = <UTC timestamp>`. See [ADR-004](../decisions/ADR-004-soft-delete.md).

### 4. Every query filters soft-deleted rows

```dart
..where((t) => t.isDeleted.equals(false))
```

Omitting this filter exposes deleted records in the UI.

---

## New Entity Checklist

When adding any new mutable table, verify all items before considering the feature complete.

### Table definition

- [ ] Has all five sync columns: `serverId`, `syncStatus`, `isDeleted`, `deletedAt`, `lastModified`
- [ ] Registered in `AppDatabase` `@DriftDatabase(tables: [...])`
- [ ] `AppDatabase._createIndexes()` includes FK-query indexes
- [ ] `AppDatabase.wipeAll()` includes `delete(newTable).go()`

### DAO

- [ ] All read methods return `Stream<List<...>>`
- [ ] Every query applies `isDeleted.equals(false)` filter
- [ ] Soft-delete method sets `isDeleted = 1` and `deletedAt = <now UTC>`

### Sync wiring

- [ ] `SyncQueueProcessor._entityPath()` handles the new `entityType` string
- [ ] `SyncQueueProcessor._getServerId()` handles the new entity
- [ ] `SyncQueueProcessor._updateServerId()` handles the new entity
- [ ] `PullSyncHandler` has a `_pullX()` method for the new entity

### Repository

- [ ] Writes to Drift **before** enqueuing to `SyncQueue`
- [ ] POST body includes `"local_id"` (device UUID for server correlation)

---

## Mandatory Sync Columns

Every mutable Drift table must declare these five columns:

| Column | Type | Purpose |
|--------|------|---------|
| `serverId` | `TextColumn nullable` | Set after first successful push; null until then |
| `syncStatus` | `TextColumn` default `'pending'` | `pending` / `synced` / `conflict` |
| `isDeleted` | `IntColumn` default `0` | Soft-delete flag (0 = live, 1 = deleted) |
| `deletedAt` | `TextColumn nullable` | UTC ISO 8601 timestamp of deletion |
| `lastModified` | `IntColumn` | Unix epoch ms; used by server-wins conflict resolution |

---

## Reference Implementation

`medidesk/lib/features/patients/` is the complete, production-quality example of an offline-first slice. Before implementing any new feature, read:

- `core/database/tables/patient_tables.dart` — table definition
- `core/database/daos/patient_dao.dart` — DAO patterns
- `features/patients/data/` — mapper + model pattern

---

## See Also

- [Database Schema](database-schema.md) — index strategy, soft-delete contract
- [Sync System](sync-system.md) — how the SyncQueue is processed
- [ADR-004](../decisions/ADR-004-soft-delete.md) — why soft-delete everywhere
