---
name: Sync System — Design & Open Decisions
description: How offline sync works and the unresolved conflict-resolution decisions
type: project
---

## Sync Architecture

- **Push:** SyncQueueProcessor processes `sync_queue` table (FIFO by status, next_retry_at, created_at)
- **Pull (mutable):** PullSyncHandler uses `?updated_after=<ISO8601 UTC>` delta pulls; response shape: `{ results, next, count }`
- **Pull (lookup):** LookupSyncHandler for chambers, users, specialities, doctor-profiles, medicines
- **File uploads:** FileUploadQueue → `POST /report-documents/` multipart
- **Background:** WorkManager 15-min periodic task (online-only)
- **Conflict default:** server-wins via `last_modified` timestamp

## Sync Correlation

Every POST body includes `"local_id": "<uuid>"`.
Server echoes `local_id` in 201 response → app stores `server_id` for the local record.

## Open Conflict-Resolution Decisions (NOT yet decided — require product input)

1. **prescription_items** — current: replace-wholesale (`replaceItems()` deletes all + reinserts).
   Risk: offline addition silently lost if concurrent edit on another device.
   Options: A) keep server-wins wholesale; B) merge by item ID + server emits `deleted_item_ids`.

2. **invoice_items** — same issue as prescription_items; recommend same decision for consistency.

3. **consultation vitals** — concurrent doctor/nurse edit drops one update under server-wins.
   Fix option: separate `ConsultationVitals` table with its own `last_modified`.

4. **appointment.status** — server-wins can roll back a forward transition (e.g., `in_progress` → `confirmed`).
   Fix: only sync forward transitions; if serverStatus is earlier in lifecycle than localStatus, keep local + mark `syncStatus = 'pending'`.

5. **patient_note** — append-only, no conflict possible. Server-wins is safe. ✅

**Why this matters:** Any work touching prescriptions, invoices, consultations, or appointments must not assume conflict resolution is solved — flag to user before shipping.
