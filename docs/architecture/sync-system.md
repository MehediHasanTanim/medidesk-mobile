# Sync System

→ [Back to docs](../README.md)

---

## Overview

```
Device                            Server
──────                            ──────
[User action]
    │
    ▼
[Drift write]
    │
    ▼
[SyncQueue row]  ──── push (PATCH/POST/DELETE) ───►  Django REST
                 ◄─── echo local_id in 201 ─────────
                      (app stores server_id)

[WorkManager / foreground trigger]
    │
    ▼
[PullSyncHandler] ◄──── GET ?updated_after=<ts> ────  Django REST
    │                   { results, next, count }
    ▼
[Drift upsert]
```

---

## Push — SyncQueueProcessor

- Reads `sync_queue` ordered by `(status='pending', next_retry_at ASC, created_at ASC)`
- For each entry: calls the appropriate REST method based on `operation` (`CREATE` / `UPDATE` / `DELETE`)
- On 201: stores `server_id` returned in response, sets `syncStatus = 'synced'`
- On 4xx: marks entry `failed`, increments retry count, sets next retry with backoff
- On 5xx / network error: leaves as `pending`, next retry at `now + backoff`

---

## Pull — PullSyncHandler (mutable entities)

Delta pull pattern for all mutable entities:

```
GET /patients/?updated_after=<last_pull_ts>&limit=500
→ { results: [...], next: "<url|null>", count: N }
```

- Follows `next` pagination until exhausted
- Records with `is_deleted: true` are soft-deleted locally
- Upserts by `server_id`; if no local record exists, inserts new

Entities pulled: patients, appointments, consultations, prescriptions, prescription-items, test-orders, invoices, invoice-items, payments.

---

## Pull — LookupSyncHandler (read-only reference data)

Full-list refresh (no `updated_after`):

- `/chambers/`, `/users/`, `/specialities/`, `/doctor-profiles/` — flat lists, replace-all strategy
- `/medicines/generic/` and `/medicines/brand/` — paginated (`page=N&limit=500`)

---

## Background Sync

- **Trigger:** WorkManager periodic task, minimum interval 15 minutes, online-only constraint
- **Entry point:** `core/sync/background_sync_task.dart` → `BackgroundSyncTask.execute()`
- **Order:** Push first (flush queue), then pull (receive server changes)
- **Foreground sync:** `SyncService.syncNow()` can be triggered manually (e.g., on app foreground)

---

## Conflict Resolution — Current Default

**Server wins via `last_modified`.** If the server record's `last_modified` is newer than the local record, the server value overwrites local.

---

## Open Conflict Decisions — Require Product Input

These cases are **not resolved**. Work touching the affected entities must not assume conflict resolution is correct until a decision is logged here and implemented.

### 1. `prescription_items` and `invoice_items`

**Current:** `replaceItems()` deletes all local items and re-inserts from server payload.

**Risk:** An offline addition is silently lost if another device edits concurrently.

**Options:**
- A) Keep server-wins wholesale (acceptable if single-author constraint is enforced)
- B) Merge by item ID; server emits `deleted_item_ids` in payload

### 2. `consultation` vitals

**Risk:** Doctor edits diagnosis + nurse records vitals offline on separate devices → one update is dropped.

**Option:** Separate `ConsultationVitals` table with its own `last_modified` so each field-set can win independently.

### 3. `appointment.status` forward-only transitions

**Risk:** Server-wins rolls back `in_progress` → `confirmed` when a patient has checked in offline.

**Fix:** In `AppointmentDao.updateStatus`, only accept server status if it is *later* in the lifecycle than local status. Otherwise keep local + re-mark `syncStatus = 'pending'`.

### 4. `patient_note`

Append-only. No conflict possible. Server-wins is safe. ✅

---

## See Also

- [Offline-First](offline-first.md) — invariants and write-local-first rule
- [API Contract](api-contract.md) — server endpoint shapes
- [ADR-002](../decisions/ADR-002-server-wins-sync.md) — why server-wins was chosen
