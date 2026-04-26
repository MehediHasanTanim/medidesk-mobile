# MediDesk Mobile — Architecture & Developer Reference

## Build-Runner Invocation

All three code-generation packages (Drift, Freezed/json_serializable, Riverpod Generator)
run in **one** `build_runner` pass:

```bash
# Step 1 — run from the project root (medidesk/)
flutter pub get

# Step 2 — single pass generates everything
flutter pub run build_runner build --delete-conflicting-outputs
```

What each generator produces:
| Package | Input | Output |
|---|---|---|
| `drift_dev` | `*.dart` tables + `@DriftDatabase` | `app_database.g.dart`, `*_dao.g.dart` |
| `freezed` | `@freezed` classes | `*.freezed.dart` |
| `json_serializable` | `@JsonSerializable` | `*.g.dart` |
| `riverpod_generator` | `@riverpod` / `class X extends _$X` | `*_providers.g.dart` |

> All generated files are git-ignored. Run `build_runner watch` during development.

---

## REST API Endpoint Assumptions

The mobile app assumes the following Django REST Framework contract.
All paths are relative to `AppConfig.current.baseUrl` (e.g. `https://api.medidesk.app/api/v1`).

### Authentication
| Method | Path | Body / Response |
|---|---|---|
| POST | `/auth/token/` | `{username, password}` → `{access, refresh, user: {id, role, ...}}` |
| POST | `/auth/token/refresh/` | `{refresh}` → `{access}` |
| POST | `/auth/logout/` | `{refresh}` → 204 |
| GET | `/auth/me/` | → `UserRow` object |

### Lookup (read-only, flat list responses)
| Method | Path | Notes |
|---|---|---|
| GET | `/chambers/` | Returns full list (no pagination needed — small set) |
| GET | `/users/` | Returns all active staff |
| GET | `/specialities/` | Flat list |
| GET | `/doctor-profiles/` | Flat list |
| GET | `/medicines/generic/?page=N&limit=500` | Paginated `{results, next, count}` |
| GET | `/medicines/brand/?page=N&limit=500` | Paginated `{results, next, count}` |

### Mutable Resources (delta-sync pattern)
All mutable endpoints support `?updated_after=<ISO8601 UTC>` for delta pulls.
Response shape: `{ results: [...], next: "<url or null>", count: N }`.

| Method | Path | Notes |
|---|---|---|
| GET | `/patients/?updated_after=&limit=500` | Delta pull |
| POST | `/patients/` | Body includes `local_id` (device UUID) for correlation |
| PATCH | `/patients/<server_id>/` | Partial update |
| DELETE | `/patients/<server_id>/` | Soft-delete on server (sets `is_deleted=true`) |
| — | (same pattern for all mutable entities) | — |

### Sync correlation field
Every POST body sent by the mobile app includes `"local_id": "<uuid>"`.
The server **must** echo `local_id` back in the 201 response so the app can
match the response to a local record and store the assigned `server_id`.

### Soft-delete contract
Deleted records are returned in delta pulls with `"is_deleted": true`.
The server never hard-deletes records — it sets `is_deleted=true` and
`deleted_at=<timestamp>`.

### File uploads
`POST /report-documents/` with `multipart/form-data`:
```
file        — binary
patient_id  — UUID
category    — blood_test | imaging | biopsy | other
test_order_id (optional)
notes (optional)
```
Response: `{ id, patient_id, category, file_url, created_at, ... }`

---

## Sync Conflict Resolution — Product Decisions Required

The current implementation uses **server-wins** via `last_modified` timestamp.
The following cases need an explicit product decision before shipping:

### 1. `prescription_items` — replace-wholesale vs merge-by-item
**Current behaviour:** `replaceItems()` in `PrescriptionDao` deletes all local
items for a prescription and re-inserts from the server payload.

**Risk:** If a doctor adds a drug offline while a receptionist concurrently
removes one on another device, the offline addition is silently lost.

**Decision options:**
- A) Server-wins wholesale (current) — simplest, acceptable if prescriptions
  are only edited by one person at a time.
- B) Merge by `prescription_item.id` — keep local items whose IDs don't
  appear in the server delete list; add new server items. Requires the server
  to emit a `deleted_item_ids` list in the prescription payload.

### 2. `invoice_items` — same issue as prescription_items above.
**Recommendation:** same decision as prescription_items for consistency.

### 3. `consultation` vitals — concurrent edit by doctor + nurse
If a nurse records weight/height offline while a doctor edits diagnosis on
another device, the current server-wins policy drops one of the two edits.

**Decision option:** Split vitals into a separate `ConsultationVitals` table
with its own `last_modified`, so each field set can win independently.

### 4. `appointment.status` — state-machine conflicts
If an appointment is `confirmed` on the server but `in_progress` locally
(patient checked in offline), server-wins would roll the status back.

**Recommended fix:** In `AppointmentDao.updateStatus`, only sync **forward**
transitions: if `serverStatus` is earlier in the lifecycle than `localStatus`,
keep the local value and mark `syncStatus = 'pending'` for re-push.

### 5. `patient_note` — no conflict; append-only
Notes are never edited after creation. Server-wins is safe. ✅

---

## Recommended Drift Indexes (Beyond Schema Spec)

Already created in `AppDatabase._createIndexes()`:

| Table | Index | Purpose |
|---|---|---|
| `sync_queue` | `(status, next_retry_at, created_at)` | FIFO pending-item fetch |
| `patients` | `full_name`, `phone`, `patient_id` | Free-text search |
| `appointments` | `(scheduled_at, status)` | Day-view list |
| `appointments` | `(patient_id, scheduled_at)` | Patient history |
| `appointments` | `(doctor_id, scheduled_at)` | Doctor schedule |
| `consultations` | `(patient_id, created_at)` | Patient timeline |
| `prescriptions` | `patient_id` | Active prescriptions lookup |
| `prescription_items` | `prescription_id` | Item fetch per prescription |
| `test_orders` | `patient_id`, `ordered_at` | Patient test history |
| `invoices` | `(created_at, status)` | Invoice dashboard |
| `invoices` | `patient_id` | Patient billing |

**Additional indexes to add as data grows:**
```sql
-- Unsynced record sweep (background sync task)
CREATE INDEX idx_patients_sync ON patients(sync_status) WHERE is_deleted = 0;
CREATE INDEX idx_appointments_sync ON appointments(sync_status) WHERE is_deleted = 0;

-- Chamber + date compound (queue view)
CREATE INDEX idx_appt_chamber_date ON appointments(chamber_id, scheduled_at, status);

-- Brand medicine FTS (if SQLite FTS5 is available)
-- Consider drift's VirtualTable + fts5 extension for medicine search > 50k rows
```

---

## Schema Fields Intentionally Excluded from the Mobile App

| Field | Server-side location | Reason excluded |
|---|---|---|
| `users.password_hash` | `Users` table | Never transmitted; auth is token-only |
| `users.last_login` | `Users` table | Read-only audit field; not needed in app |
| `users.permissions` / `groups` | `Users` table | RBAC is enforced server-side; app uses `role` only |
| `doctor_profiles.rating` | `DoctorProfiles` | Future feature; out of scope for v1 |
| `doctor_profiles.clinic_registration_no` | `DoctorProfiles` | Compliance field displayed in PDF only |
| `patients.photo_url` | `Patients` | Excluded: file caching not in v1 scope |
| `report_documents.file_binary` | `ReportDocuments` | Binary not cached locally; display via `file_url` only |
| `prescriptions.digital_signature` | `Prescriptions` | Requires PKI; deferred to v2 |
| `invoices.tax_amount` | `Invoices` | Tax not applicable in current BD clinic context |
| `payments.cheque_date` | `Payments` | Cheque payment method not in v1 |
| `audit_log.*` | Audit tables | Server-side only; never synced down |
| `notification_settings.*` | User preferences | Server push notifications deferred to v2 |

---

## Offline-First Invariants (Checklist for New Features)

When adding a new mutable entity, verify all of the following:

- [ ] Table has `server_id`, `sync_status`, `is_deleted`, `deleted_at`, `last_modified` columns
- [ ] DAO returns `Stream<...>` (not `Future<List>`) for all read operations
- [ ] Repository writes to Drift **before** enqueuing to `SyncQueue`
- [ ] `SyncQueueProcessor._entityPath()` handles the new `entityType` string
- [ ] `SyncQueueProcessor._getServerId()` handles the new entity
- [ ] `SyncQueueProcessor._updateServerId()` handles the new entity
- [ ] `PullSyncHandler` has a corresponding `_pullX()` method
- [ ] `AppDatabase.wipeAll()` includes a `delete(newTable).go()` call
- [ ] `AppDatabase._createIndexes()` registers any foreign-key query indexes
- [ ] Soft-delete is used everywhere — `isDeleted == 0` filter in every DAO query

---

## Timezone Rules

- All timestamps are **stored as UTC ISO 8601** strings in Drift.
- The **only place** UTC → local conversion happens is `DateFormatter` in `core/utils/date_formatter.dart`.
- The timezone package's `tz.initializeTimeZones()` is called in `main()` before `runApp`.
- `Asia/Dhaka` is UTC+6, no DST. If the clinic operates in another timezone, change `_dhaka` in `DateFormatter`.

---

## Currency Display

All monetary values are stored as `REAL` (BDT, no sub-unit precision beyond 2 dp).
Display rule: `DateFormatter.formatBdt(amount)` → `৳ 1,250.00`.

Invoice totals are **computed in the UI layer** (not stored):
```
subtotal = sum(quantity × unit_price)    for all non-deleted invoice_items
total    = subtotal × (1 - discount_percent / 100)
paid     = sum(amount)                   for all non-deleted payments
balance  = total - paid
```

---

## Directory Quick Reference

```
lib/
├── core/
│   ├── config/          app_config.dart, router_config.dart
│   ├── database/        Drift tables, DAOs, app_database.dart
│   ├── enums/           app_enums.dart (all Dart enums)
│   ├── error/           app_exception.dart (sealed), error_handler.dart
│   ├── network/         DioClient + 3 interceptors + api_endpoints.dart
│   ├── storage/         SecureStorageService, PreferencesService
│   ├── sync/            SyncService, PullSyncHandler, SyncQueueProcessor,
│   │                    LookupSyncHandler, FileUploadQueue, ConflictResolver,
│   │                    BackgroundSyncTask (WorkManager)
│   ├── theme/           AppTheme, AppColors, AppTextStyles
│   └── utils/           DateFormatter, Validators, Extensions, IsolateHelper
│
├── features/
│   ├── patients/        ← COMPLETE (full offline-first slice)
│   └── (others)/        ← Stub screens; implement following patients/ pattern
│
├── shared/
│   ├── providers/       connectivity_provider, sync_status_provider,
│   │                    infrastructure_providers (injectable singletons)
│   └── widgets/         OfflineBanner, SyncStatusBadge, AppButton, etc.
│
└── main.dart            ProviderScope overrides, WorkManager init, tz init
```
