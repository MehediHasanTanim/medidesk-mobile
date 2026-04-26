# Skill: debug-sync
**Systematically diagnose sync failures in MediDesk**

Use when: records are stuck as `syncStatus = 'pending'`, server IDs are never written back,
delta pulls are missing data, or the sync queue isn't draining.

---

## Step 1 — Identify the Failure Class

Ask the user (or inspect logs) to classify:

| Symptom | Failure Class |
|---|---|
| Records stuck on `syncStatus = 'pending'` indefinitely | Push failure |
| Server changes not appearing locally | Pull failure |
| `serverId` is null after a successful POST | Correlation failure |
| Record appears deleted locally but exists on server | Soft-delete contract mismatch |
| Appointments/prescriptions reverting status | Conflict resolution (server-wins rollback) |
| Lookup data (medicines, chambers) stale | LookupSyncHandler failure |

---

## Step 2 — Push Failure Diagnosis

Check `SyncQueueProcessor` in `core/sync/sync_queue_processor.dart`:

1. **Entity path missing** — is `_entityPath(entityType)` returning `null` for the stuck entity type?
   - Fix: add the case to `_entityPath()`

2. **serverId lookup failing** — is `_getServerId(entityType, localId)` throwing or returning null?
   - Means the entity's DAO is not queried, or `serverId` was never stored
   - Fix: add case to `_getServerId()` + verify `_updateServerId()` is called on 201

3. **Payload missing `local_id`** — check the JSON payload in `sync_queue.payload_json`
   - Every CREATE must include `"local_id": "<uuid>"` or server won't echo it back

4. **Network / auth** — check `DioClient` interceptors:
   - `auth_interceptor.dart` — token attached correctly?
   - `error_interceptor.dart` — 401 triggering refresh? 429 being retried?
   - `logging_interceptor.dart` — enable and read the request/response logs

5. **WorkManager not firing** — background sync only runs every 15 min and only when online
   - For immediate debug: call `syncService.pushSync()` directly

---

## Step 3 — Pull Failure Diagnosis

Check `PullSyncHandler` in `core/sync/pull_sync_handler.dart`:

1. **Method missing** — is `_pull<EntityName>()` implemented and called from `pullAll()`?

2. **`updated_after` timestamp stale** — check `PreferencesService` for the stored cursor
   - If the cursor is far in the past, a large batch may be timing out
   - Try a full pull by clearing the cursor: `prefs.clearLastSyncTime('<entity>')`

3. **Pagination not followed** — delta responses include `next` URL; confirm the handler loops until `next == null`

4. **`is_deleted` records not applied** — check that the DAO's upsert handles `is_deleted = true` by calling `softDelete()` rather than ignoring the record

5. **Lookup tables (chambers, medicines)** — these go through `LookupSyncHandler`, not `PullSyncHandler`
   - Medicines are paginated (`/medicines/generic/?page=N&limit=500`) — confirm the handler follows `next`

---

## Step 4 — Correlation Failure (serverId never stored)

Sequence for a CREATE:
```
mobile POST /patients/ {local_id: "abc", ...}
server 201 {id: 99, local_id: "abc", ...}   ← server MUST echo local_id
SyncQueueProcessor reads local_id from response
calls _updateServerId('patient', 'abc', '99')
PatientDAO updates serverId = '99', syncStatus = 'synced'
```

Check each step:
- Does the 201 response body contain `local_id`? (log it via `logging_interceptor`)
- Is `_updateServerId` handling this `entityType`?
- Does the DAO update `syncStatus` to `'synced'` and write `serverId`?

---

## Step 5 — Conflict Resolution Issues

These are **known unresolved decisions** (see `.claude/memory/sync_system.md`):

- `prescription_items` / `invoice_items`: replace-wholesale may silently drop offline edits
- `consultation` vitals: concurrent doctor + nurse edits lose one write
- `appointment.status`: server-wins can roll back forward transitions

For appointment status rollback, the recommended fix:
```dart
// In AppointmentDao.updateStatus — only sync forward
final statusOrder = ['scheduled', 'confirmed', 'in_progress', 'completed', 'cancelled'];
if (statusOrder.indexOf(serverStatus) <= statusOrder.indexOf(localStatus)) {
  // keep local, re-enqueue for push
  return;
}
```

---

## Step 6 — Verify & Report

After identifying the root cause:

1. State the failure class and exact location (`file:line`)
2. Show the minimal fix
3. Run `flutter analyze` to confirm no regressions
4. If it's one of the 5 unresolved conflict decisions, flag it as a product decision needed — don't silently pick server-wins

---

## Common Mistakes

| Mistake | Symptom |
|---|---|
| `Future<List>` instead of `Stream` in DAO | UI never updates after sync |
| Drift write after sync enqueue | Queue fires before data exists locally |
| Missing `isDeleted == 0` filter | Soft-deleted records appear in UI |
| `entityType` string typo | Queue entry never processed; stuck forever |
| Not calling `wipeAll()` on logout | Stale data from previous user session |
