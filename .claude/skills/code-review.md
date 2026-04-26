# Skill: code-review
**Review code against MediDesk patterns and offline-first invariants**

Use when the user asks to review a file, PR diff, or newly written feature.

---

## Review Checklist

Run through every section. Report findings as: `FAIL`, `WARN`, or `OK`.

### 1. Offline-First Invariants

- [ ] Every mutable Drift table has: `server_id`, `sync_status`, `is_deleted`, `deleted_at`, `last_modified`
- [ ] Every DAO read method returns `Stream<...>` — flag any `Future<List<...>>` reads
- [ ] Every mutation writes to Drift FIRST, then enqueues to `sync_queue`, then calls `unawaited(_syncService.pushSync())`
- [ ] Every DAO query filters `WHERE is_deleted = 0` (or `.where((t) => t.isDeleted.equals(0))` in Drift DSL)
- [ ] Soft-delete: mutations call `softDelete()` and enqueue `operation: 'DELETE'` — never hard-delete

### 2. Sync Queue Correctness

- [ ] Payload JSON includes `'local_id': localId` on CREATE operations
- [ ] `entityType` string is registered in `SyncQueueProcessor._entityPath()`
- [ ] New entity type is handled in `_getServerId()` and `_updateServerId()`
- [ ] `PullSyncHandler` has a corresponding `_pull<X>()` method
- [ ] `AppDatabase.wipeAll()` includes `delete(<newTable>).go()`

### 3. Riverpod Conventions

- [ ] Stream/list providers use `@riverpod` annotation (not manual `StreamProvider`)
- [ ] Mutation notifiers extend `_$<Name>Notifier`, set `state = const AsyncLoading()` before async work
- [ ] `AsyncValue.guard()` wraps repository calls in notifiers
- [ ] No direct `ref.read()` in build methods — only in event handlers/callbacks
- [ ] Repository provider uses `ref.watch(appDatabaseProvider)` and `ref.watch(syncServiceProvider)`

### 4. Data Layer

- [ ] Mapper class is `abstract final` — no instances, static methods only
- [ ] `toCreateCompanion` sets `syncStatus: const Value('pending')`, `isDeleted: const Value(0)`
- [ ] Timestamps: `createdAt`/`updatedAt` = `DateTime.now().toUtc().toIso8601String()`, `lastModified` = `DateTime.now().millisecondsSinceEpoch`
- [ ] JSON list fields (e.g. allergies) go through `jsonEncode`/`jsonDecode` in mapper
- [ ] No `toJson` in mapper — serialisation is handled by `json_serializable` on freezed models

### 5. Currency & Timezone

- [ ] Monetary display uses `DateFormatter.formatBdt(amount)` — no raw `.toString()` on amounts
- [ ] Invoice totals computed in UI layer, not stored
- [ ] No direct `DateTime.now()` for display — goes through `DateFormatter` for UTC→local conversion
- [ ] No hardcoded `'Asia/Dhaka'` string outside `DateFormatter`

### 6. Code Quality

- [ ] No `Future<List>` where `Stream<List>` is expected by Riverpod watcher
- [ ] No `print()` statements — use logging interceptor
- [ ] No hardcoded base URLs — must use `AppConfig.current.baseUrl`
- [ ] Fields excluded from mobile schema are absent: `password_hash`, `permissions`, `photo_url`, `digital_signature`, `tax_amount`, `audit_log`

### 7. Generated Files

- [ ] `.g.dart` and `.freezed.dart` files are not manually edited
- [ ] `part 'foo.g.dart'` and `part 'foo.freezed.dart'` declarations present where needed
- [ ] `build_runner` was run after changes (check for stale generated files)

---

## Output Format

```
## Code Review: <file or feature name>

### FAIL
- <specific issue with file:line reference>

### WARN
- <non-blocking concern>

### OK
- Offline-first invariants: all present
- Riverpod pattern: correct

### Recommended Actions
1. ...
```

If all checks pass: state explicitly "No issues found — matches MediDesk patterns."
