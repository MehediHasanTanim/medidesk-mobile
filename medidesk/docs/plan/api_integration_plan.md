# API Integration Plan — MediDesk Mobile (Offline-First)

**Backend Base URL:** `http://localhost:8005/api/v1`
**Dev emulator URL:** `http://10.0.2.2:8005/api/v1`
**Schema source:** `http://localhost:8005/api/docs/`
**Architecture ref:** `ARCHITECTURE.md`
**Date:** 2026-04-26

---

## 0. How to Read This Document

Every section follows the same structure:

1. **What exists** — DB table, DAO, sync wiring already in place
2. **API contract** — actual endpoints from the live Swagger schema
3. **Offline-first flow** — write path (local → queue → push) and read path (pull → Drift → stream)
4. **Gaps / action items** — concrete file changes needed

The **patients** feature is the reference implementation. Every other mutable feature follows the same pattern.

---

## 1. Critical Blockers — Fix Before Any Feature Work

### 1.1 Endpoint URL Mismatches

`lib/core/network/api_endpoints.dart` has wrong paths. The backend has diverged from the
ARCHITECTURE.md contract. These mismatches break **auth, lookup sync, and file upload** right now.

| Constant / usage | Current (broken) | Correct |
|---|---|---|
| `login` | `/auth/token/` | `/auth/login/` |
| `refreshToken` | `/auth/token/refresh/` | `/auth/refresh/` |
| `doctorProfiles` (LookupSyncHandler) | `/doctor-profiles/` | `/doctors/profiles/` |
| `genericMedicines` (LookupSyncHandler) | `/medicines/generic/` | `/medicines/generics/` |
| `brandMedicines` (LookupSyncHandler) | `/medicines/brand/` | `/medicines/brands/` |
| `reportDocuments` (FileUploadQueue) | `/report-documents/` | `/reports/` |
| `patientNotes` (SyncQueueProcessor) | `/patient-notes/` | `/patients/{id}/notes/` (path param — see §6.5) |

**Action:** Replace `api_endpoints.dart` entirely with the corrected version in §1.3.

### 1.2 Delta-Sync Parameter Mismatch

`PullSyncHandler._pullPaginated()` sends `?updated_after=<ISO8601>` to every mutable
endpoint. The actual API **does not implement `updated_after`** on any endpoint in the current
schema. This means every pull is silently a full-pull (the param is ignored by the server),
which is safe but inefficient.

**Decision required (backend + mobile together):**

| Option | Work | Recommendation |
|---|---|---|
| A — Backend adds `?updated_after=` to all mutable list endpoints | Backend work | **Preferred** — preserves the delta-sync design |
| B — Mobile drops `updated_after` and always full-pulls with pagination | No backend work | Acceptable for small clinics (<5k records); add a record-count guard |
| C — Backend exposes a `/sync/changes/?since=` endpoint that returns all changed entity IDs | Backend work | Best long-term but out of scope for v1 |

**Until the backend adds `updated_after`,** the `_pullPaginated` call will work correctly
(full pull every time), just without efficiency gains. Keep the code as-is so it automatically
becomes delta-aware once the backend is updated.

### 1.3 Corrected `api_endpoints.dart`

Replace the entire file:

```dart
// lib/core/network/api_endpoints.dart
abstract final class ApiEndpoints {
  // ── Auth ──────────────────────────────────────────────────────────────
  static const String login           = '/auth/login/';
  static const String refreshToken    = '/auth/refresh/';
  static const String logout          = '/auth/logout/';
  static const String me              = '/auth/me/';
  static const String changePassword  = '/auth/change-password/';

  // ── Users ─────────────────────────────────────────────────────────────
  static const String users           = '/users/';
  static const String doctors         = '/users/doctors/';
  static String userDetail(String id) => '/users/$id/';

  // ── Chambers ──────────────────────────────────────────────────────────
  static const String chambers            = '/chambers/';
  static String chamberDetail(String id)  => '/chambers/$id/';

  // ── Patients ──────────────────────────────────────────────────────────
  static const String patients             = '/patients/';
  static const String patientSearch        = '/patients/search/';
  static String patientDetail(String id)   => '/patients/$id/';
  static String patientHistory(String id)  => '/patients/$id/history/';
  static String patientNotes(String id)    => '/patients/$id/notes/';

  // ── Appointments ──────────────────────────────────────────────────────
  static const String appointments          = '/appointments/';
  static const String appointmentQueue      = '/appointments/queue/';
  static const String appointmentStream     = '/appointments/queue/stream/';
  static const String walkIn                = '/appointments/walk-in/';
  static String appointmentDetail(String id)   => '/appointments/$id/';
  static String appointmentCheckIn(String id)  => '/appointments/$id/check-in/';
  static String appointmentStatus(String id)   => '/appointments/$id/status/';

  // ── Consultations ─────────────────────────────────────────────────────
  static const String consultations              = '/consultations/';
  static String consultationDetail(String id)    => '/consultations/$id/';
  static String consultationComplete(String id)  => '/consultations/$id/complete/';
  static String consultationVitals(String id)    => '/consultations/$id/vitals/';
  static String consultationTestOrders(String id)=> '/consultations/$id/test-orders/';

  // ── Prescriptions ─────────────────────────────────────────────────────
  static const String prescriptions                    = '/prescriptions/';
  static const String pendingPrescriptions             = '/prescriptions/pending/';
  static String prescriptionDetail(String id)          => '/prescriptions/$id/';
  static String prescriptionApprove(String id)         => '/prescriptions/$id/approve/';
  static String prescriptionPdf(String id)             => '/prescriptions/$id/pdf/';
  static String prescriptionSend(String id)            => '/prescriptions/$id/send/';
  static String prescriptionByConsultation(String cId) => '/prescriptions/consultation/$cId/';

  // ── Billing ───────────────────────────────────────────────────────────
  static const String invoices            = '/invoices/';
  static const String payments            = '/payments/';
  static const String incomeReport        = '/income-report/';
  static String invoiceDetail(String id)  => '/invoices/$id/';
  static String invoicePdf(String id)     => '/invoices/$id/pdf/';

  // ── Test Orders ───────────────────────────────────────────────────────
  static const String testOrders            = '/test-orders/';
  static const String myTestOrders          = '/test-orders/mine/';
  static const String pendingTestOrders     = '/test-orders/pending/';
  static String testOrderDetail(String id)  => '/test-orders/$id/';

  // ── Reports ───────────────────────────────────────────────────────────
  static const String reports             = '/reports/';
  static String reportDetail(String id)   => '/reports/$id/';
  static String reportFile(String id)     => '/reports/$id/file/';

  // ── Medicines ─────────────────────────────────────────────────────────
  static const String medicineSearch   = '/medicines/search/';
  static const String generics         = '/medicines/generics/';
  static const String brands           = '/medicines/brands/';
  static const String manufacturers    = '/medicines/manufacturers/';
  static String genericDetail(String id)       => '/medicines/generics/$id/';
  static String brandDetail(String id)         => '/medicines/brands/$id/';
  static String manufacturerDetail(String id)  => '/medicines/manufacturers/$id/';

  // ── Doctors ───────────────────────────────────────────────────────────
  static const String specialities          = '/specialities/';
  static const String doctorProfiles        = '/doctors/profiles/';
  static String specialityDetail(String id)     => '/specialities/$id/';
  static String doctorProfileDetail(String id)  => '/doctors/profiles/$id/';

  // ── Dashboard & Audit ─────────────────────────────────────────────────
  static const String dashboard  = '/dashboard/';
  static const String auditLogs  = '/audit-logs/';
}
```

Also fix `AppConfig.development.baseUrl`: change port `8000` → `8005`.

---

## 2. Offline-First Architecture Reference

### 2.1 The Two Sync Paths

```
┌─────────────────────────────────────────────────────────┐
│                   WRITE PATH (offline-safe)              │
│                                                          │
│  UI Action                                               │
│     │                                                    │
│     ▼                                                    │
│  Repository.create/update/delete()                       │
│     │                                                    │
│     ├─1─▶ Drift INSERT/UPDATE (immediate, optimistic)   │
│     │                                                    │
│     ├─2─▶ SyncQueue.enqueue(entityType, op, localId,    │
│     │         payloadJson)                               │
│     │                                                    │
│     └─3─▶ SyncService.pushSync() — non-blocking         │
│              │ (online?)                                 │
│              ▼                                           │
│           SyncQueueProcessor.pushSync()                  │
│              │                                           │
│              ▼                                           │
│           Dio POST/PATCH/DELETE → server                 │
│              │                                           │
│              ▼ (on CREATE success)                       │
│           store returned server_id in local row          │
│           mark syncStatus = 'synced'                     │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                   READ PATH (reactive)                   │
│                                                          │
│  App launch / foreground / background (WorkManager)     │
│     │                                                    │
│     ▼                                                    │
│  SyncService.initialize()                                │
│     │                                                    │
│     ├─1─▶ LookupSyncHandler.syncAll()                   │
│     │       → GET /chambers/, /users/, /specialities/,  │
│     │         /doctors/profiles/, /medicines/generics/,  │
│     │         /medicines/brands/                         │
│     │       → upsert into Drift lookup tables            │
│     │                                                    │
│     ├─2─▶ PullSyncHandler.pullSync()                    │
│     │       → GET /patients/, /appointments/,            │
│     │         /consultations/, /prescriptions/,          │
│     │         /test-orders/, /invoices/                  │
│     │       → conflict-resolve & upsert into Drift       │
│     │                                                    │
│     └─3─▶ SyncQueueProcessor.pushSync()                 │
│              → flush any queued writes                   │
│                                                          │
│  Screen watches Drift Stream<List<T>>                   │
│     → auto-rebuilds when Drift table changes             │
└─────────────────────────────────────────────────────────┘
```

### 2.2 Offline-First Invariants Checklist (from ARCHITECTURE.md)

Every new mutable entity **must** satisfy all of the following before the feature is considered complete:

- [ ] Drift table has `server_id`, `sync_status`, `is_deleted`, `deleted_at`, `last_modified`
- [ ] DAO exposes `Stream<List<T>>` for all read operations (not `Future<List>`)
- [ ] DAO filters `WHERE is_deleted = 0` on every query
- [ ] Repository writes to Drift **before** enqueuing to SyncQueue
- [ ] POST body includes `"local_id": localId` for server correlation
- [ ] `SyncQueueProcessor._entityPath()` handles the entity type string
- [ ] `SyncQueueProcessor._getServerId()` handles the entity type
- [ ] `SyncQueueProcessor._updateServerId()` handles the entity type
- [ ] `PullSyncHandler` has a `_pullX()` method using `_pullPaginated()`
- [ ] Soft-delete: `repository.delete()` sets `is_deleted=1`, enqueues `DELETE` op
- [ ] `AppDatabase.wipeAll()` includes `delete(newTable).go()`
- [ ] `AppDatabase._createIndexes()` registers FK-query indexes

### 2.3 Sync Status Values

All mutable rows carry `sync_status`:

| Value | Meaning |
|---|---|
| `pending` | Created/modified locally, not yet sent to server |
| `processing` | Currently being pushed by SyncQueueProcessor |
| `synced` | Confirmed round-trip with server |
| `failed` | Push failed after `maxRetries` (3); needs manual retry or investigation |

### 2.4 Conflict Resolution Policy

**Default:** server-wins via `last_modified` (epoch ms). See `conflict_resolver.dart`.

**Known exceptions requiring product decisions** (from ARCHITECTURE.md):

| Entity | Conflict scenario | Recommended resolution |
|---|---|---|
| `prescription_items` | Doctor adds drug offline; receptionist deletes one server-side | Decision A (server-wins wholesale) or B (merge by item ID) |
| `invoice_items` | Same as prescription_items | Match prescription_items decision |
| `consultation` vitals | Nurse records weight offline; doctor edits diagnosis on server | Split vitals to separate `ConsultationVitals` table with own `last_modified` |
| `appointment.status` | Checked-in offline; server still shows `scheduled` | Only sync forward state-machine transitions (see §4.3) |
| `patient_notes` | Append-only; no edit | Server-wins is safe ✓ |

### 2.5 Online-Only Actions

These actions **cannot be queued** — they require immediate server response and must block on
connectivity. Show an `OfflineBanner` / disable the button when offline.

| Action | Reason |
|---|---|
| Auth: login, logout, change-password | Token management |
| `POST /appointments/{id}/check-in/` | Token number is assigned by server |
| `PATCH /appointments/{id}/status/` | State-machine enforced server-side |
| `POST /consultations/{id}/complete/` | Triggers invoice generation, status chain |
| `POST /prescriptions/{id}/approve/` | Approval is an authorization action |
| `POST /prescriptions/{id}/send/` | External delivery (WhatsApp/email) |
| `GET /prescriptions/{id}/pdf/` | Binary streaming |
| `GET /invoices/{id}/pdf/` | Binary streaming |
| `GET /reports/{id}/file/` | Binary streaming |
| `GET /appointments/queue/` | Real-time queue state |
| `GET /appointments/queue/stream/` | SSE — by definition live |
| `GET /dashboard/` | Live aggregate stats |
| `GET /income-report/` | Live financial report |
| `GET /audit-logs/` | Server-side audit records |

---

## 3. Phase 1 — Auth Feature

### 3.1 Current State
- Screen exists: `lib/features/auth/presentation/screens/login_screen.dart`
- **No** data layer (no model, no repository, no provider)
- `AuthInterceptor` exists but needs to be verified for the refresh-retry loop

### 3.2 Files to Create

```
lib/features/auth/
  data/
    models/auth_models.dart
    repositories/auth_repository.dart
  presentation/
    providers/auth_providers.dart
```

### 3.3 API Contract

| Op | Method | Endpoint | Body | Response |
|---|---|---|---|---|
| Login | POST | `/auth/login/` | `{username, password}` | `{access, refresh, user{id,username,full_name,email,role,chamber_ids,is_active}}` |
| Refresh | POST | `/auth/refresh/` | `{refresh}` | `{access}` |
| Logout | POST | `/auth/logout/` | `{refresh}` | 204 / `{detail}` |
| Get profile | GET | `/auth/me/` | — | `Me` schema |
| Update profile | PATCH | `/auth/me/` | `{full_name?, email?}` | `Me` schema |
| Change password | POST | `/auth/change-password/` | `{old_password, new_password}` | `{detail}` |

### 3.4 Offline-First Flow

Auth is **online-only** — no Drift involvement.

**Login flow:**
1. `POST /auth/login/` → receive `{access, refresh, user}`
2. Store `access` in `SecureStorageService` (key: `access_token`)
3. Store `refresh` in `SecureStorageService` (key: `refresh_token`)
4. Persist `user.id`, `user.role`, `user.chamber_ids` in `PreferencesService`
5. Trigger `SyncService.initialize()` (starts full sync)
6. Navigate to dashboard

**Logout flow:**
1. `POST /auth/logout/` with `{refresh}` (blacklists server-side)
2. Clear `SecureStorageService` (both tokens)
3. Call `AppDatabase.wipeAll()` (clears all local data)
4. Clear `PreferencesService.lastSyncTimestamp`
5. Navigate to login screen

**Token refresh (in AuthInterceptor):**
1. Request gets 401
2. Read `refresh` from `SecureStorageService`
3. `POST /auth/refresh/` — if 200: update stored `access`, retry original request
4. If refresh returns 401: clear tokens → navigate to login → cancel original request

### 3.5 Model Shape (`auth_models.dart`)

```dart
@freezed class LoginRequest    // {username, password}
@freezed class LoginResponse   // {access, refresh, user: LoginUser}
@freezed class LoginUser       // {id, username, full_name, email, role, chamber_ids, is_active}
@freezed class UserProfile     // Me schema — same as LoginUser + nullable fields
@freezed class ChangePasswordRequest  // {old_password, new_password}
```

### 3.6 No SyncQueue Involvement

Auth is not added to `SyncQueueProcessor`. No pull handler needed.

---

## 4. Phase 2 — Appointments Feature

### 4.1 Current State
- Screens exist: list, form, detail, queue management
- **Drift table:** `Appointments` ✓ — has all sync columns
- **DAO:** `AppointmentDao` ✓
- **Pull sync:** `PullSyncHandler._pullAppointments()` ✓ — pulls `GET /appointments/`
- **Push sync:** `SyncQueueProcessor` handles `'appointment'` entity type ✓
- **No** repository, models, or providers

### 4.2 API Contract

| Op | Method | Endpoint | Offline? | Query / Body |
|---|---|---|---|---|
| List appointments | GET | `/appointments/` | Pull sync | `?date=&doctor_id=&patient_id=&status=&limit=&offset=` |
| Book appointment | POST | `/appointments/` | ✅ Queue | `{patient_id, doctor_id?, scheduled_at, appointment_type, chamber_id?, notes}` + `local_id` |
| Walk-in | POST | `/appointments/walk-in/` | ✅ Queue | `{patient_id, doctor_id?, chamber_id?, notes}` + `local_id` |
| Get appointment | GET | `/appointments/{id}/` | Local read | — |
| Edit appointment | PATCH | `/appointments/{id}/` | ✅ Queue | Partial `BookAppointmentRequest` fields |
| Check-in | POST | `/appointments/{id}/check-in/` | ❌ Online-only | No body → `{token_number, status}` |
| Update status | PATCH | `/appointments/{id}/status/` | ❌ Online-only | `{status}` |
| Today's queue | GET | `/appointments/queue/` | ❌ Online-only | `?chamber_id=&date=` |
| Live queue (SSE) | GET | `/appointments/queue/stream/` | ❌ Online-only | — |

### 4.3 Offline-First Write Path

**Book appointment:**
```
1. Generate localId (UUID v4)
2. AppointmentDao.insert(AppointmentsCompanion) — scheduledAt, patientId, etc.
   syncStatus='pending', serverId=null
3. SyncQueue.enqueue(entityType:'appointment', op:'CREATE', localId, payload:{
     local_id: localId, patient_id, doctor_id, scheduled_at,
     appointment_type, chamber_id, notes
   })
4. SyncService.pushSync() — non-blocking
```

**Walk-in:** Same pattern as book, but use `entityType:'walk_in'` pointing to
`ApiEndpoints.walkIn` in `SyncQueueProcessor._entityPath()`.
Walk-in has no concept of editing after creation, so only `CREATE` is needed.

**Edit appointment:**
```
1. AppointmentDao.update(companion) — new fields + lastModified=now + syncStatus='pending'
2. SyncQueue.enqueue(entityType:'appointment', op:'UPDATE', localId, payload:{...})
3. SyncService.pushSync()
```

**Cancel / no-show (status change):**
- If **online**: call `PATCH /appointments/{id}/status/` directly → update local row on success
- If **offline**: write `status='cancelled'` locally, enqueue `UPDATE` op with `{status:'cancelled'}`

> **State machine guard (from ARCHITECTURE.md §4):** In `AppointmentDao.updateStatus`, only
> write locally if the new status is a forward transition. On pull sync, if `serverStatus` is
> earlier in the lifecycle than `localStatus`, keep local and mark `syncStatus='pending'`.
>
> Lifecycle order: `scheduled → checked_in → in_consultation → completed`
> Side exits: `cancelled`, `no_show`

### 4.4 Read Path

Screens watch `AppointmentDao` streams:
- `watchByDate(date)` — appointment list for a day
- `watchByPatient(patientId)` — patient history
- `watchById(localId)` — detail screen

Pull sync (`_pullAppointments`) upserts with server-wins conflict resolution.

### 4.5 Queue Feature (Online-Only)

`QueueManagementScreen`:
1. On screen open → `GET /appointments/queue/?chamber_id=&date=today` → display `QueueItem[]`
2. If online → open SSE: `GET /appointments/queue/stream/` with `ResponseType.stream`

```dart
// SSE pattern in appointment_providers.dart
final queueStreamProvider = StreamProvider<List<QueueItem>>((ref) async* {
  final response = await dio.get<ResponseBody>(
    ApiEndpoints.appointmentStream,
    options: Options(responseType: ResponseType.stream),
  );
  await for (final event in response.data!.stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .where((l) => l.startsWith('data:'))
      .map((l) => jsonDecode(l.substring(5)) as Map<String, dynamic>)) {
    yield _parseQueueItems(event);
  }
});
```

### 4.6 SyncQueueProcessor Changes

Add `'walk_in'` to `_entityPath()`:
```dart
'walk_in' => ApiEndpoints.walkIn,
```

Walk-in CREATE response contains `local_id`; update serverId in `_updateServerId()`.

### 4.7 Files to Create

```
lib/features/appointments/
  data/
    models/appointment_models.dart     # Appointment, CreateAppointmentRequest,
                                       # UpdateAppointmentRequest, QueueItem, CheckInResponse
    mappers/appointment_mapper.dart    # fromRow(), toCreateCompanion(), toUpdateCompanion()
    repositories/appointment_repository.dart
  presentation/
    providers/appointment_providers.dart  # appointmentsProvider, queueStreamProvider
```

---

## 5. Phase 3 — Consultations Feature

### 5.1 Current State
- Screens exist: form, detail
- **Drift table:** `Consultations` ✓ — vitals embedded in same table
- **DAO:** `ConsultationDao` ✓
- **Pull sync:** `PullSyncHandler._pullConsultations()` ✓
- **Push sync:** `SyncQueueProcessor` handles `'consultation'` entity type ✓
- **No** repository, models, or providers

### 5.2 API Contract

| Op | Method | Endpoint | Offline? |
|---|---|---|---|
| List consultations | GET | `/consultations/` | Pull sync (`?patient_id=&appointment_id=&limit=`) |
| Start consultation | POST | `/consultations/` | ✅ Queue (with `local_id`) |
| Get consultation | GET | `/consultations/{id}/` | Local read |
| Update draft | PATCH | `/consultations/{id}/` | ✅ Queue |
| Record vitals | PATCH | `/consultations/{id}/vitals/` | ✅ Queue (separate entity type) |
| Complete | POST | `/consultations/{id}/complete/` | ❌ Online-only |

### 5.3 Offline-First Write Path

**Start consultation:**
```
1. localId = UUID v4
2. ConsultationDao.insert — appointmentId, patientId, doctorId, chiefComplaints,
   isDraft=1, syncStatus='pending'
3. SyncQueue.enqueue(entityType:'consultation', op:'CREATE', localId, {
     local_id:localId, appointment_id, patient_id, chief_complaints
   })
4. SyncService.pushSync()
```

**Update draft consultation:**
```
1. ConsultationDao.update — chiefComplaints, clinicalFindings, diagnosis, notes,
   lastModified=now, syncStatus='pending'
2. SyncQueue.enqueue(entityType:'consultation', op:'UPDATE', localId, {partial fields})
3. SyncService.pushSync()
```

**Record vitals** (offline-safe, merged separately):
```
1. ConsultationDao.updateVitals — bpSystolic, bpDiastolic, pulse, temperature,
   weight, height, spo2, lastModified=now, syncStatus='pending'
2. SyncQueue.enqueue(entityType:'consultation_vitals', op:'UPDATE', localId, {
     bp_systolic, bp_diastolic, pulse, temperature, weight, height, spo2
   })
3. SyncService.pushSync()
```

> **Note on vitals conflict (ARCHITECTURE.md §3):** Currently vitals share the
> `Consultations` table and the same `last_modified`. If a nurse records weight/height
> offline while a doctor edits diagnosis on another device, server-wins drops one update.
> The long-term fix is a separate `ConsultationVitals` table. For v1, document this as
> a known risk and proceed with embedded vitals.

**Complete consultation (online-only):**
```
1. Check connectivity — show error if offline
2. Build CompleteConsultationRequest {diagnosis, clinical_findings, notes, vitals...}
3. POST /consultations/{serverId}/complete/
4. On 200: update local row isDraft=0, completedAt=now, syncStatus='synced'
5. Trigger PullSyncHandler._pullConsultations() to get server canonical state
```

### 5.4 SyncQueueProcessor Changes

Add `'consultation_vitals'` to `_entityPath()` — uses a **dynamic** path, not a constant:

```dart
// In _dispatchApiCall(), handle vitals as a special UPDATE:
case 'consultation_vitals':
  final serverId = await _getServerId('consultation', entry.localId);
  if (serverId == null) return null;  // wait for consultation CREATE to sync first
  await _dio.patch<void>(
    ApiEndpoints.consultationVitals(serverId),
    data: payload,
  );
  return null;
```

### 5.5 Files to Create

```
lib/features/consultations/
  data/
    models/consultation_models.dart    # Consultation, Vitals, StartConsultationRequest,
                                       # UpdateConsultationRequest, CompleteConsultationRequest
    mappers/consultation_mapper.dart
    repositories/consultation_repository.dart
  presentation/
    providers/consultation_providers.dart
```

---

## 6. Phase 4 — Patients Feature (Gap Fixes)

### 6.1 Current State

Patients is the **reference implementation** — fully done. However, two gaps exist.

### 6.2 Gap 1: Patient Search vs Pull List

`PullSyncHandler._pullPatients()` calls `GET /patients/` (the CREATE endpoint — POST only).
The actual list/search endpoint is `GET /patients/search/?q=&limit=&offset=`.

**Fix:**
- `PullSyncHandler._pullPatients()` → change path to `ApiEndpoints.patientSearch`
  (or request backend to add `GET /patients/?updated_after=` — preferred)
- `PatientListScreen` search → call `GET /patients/search/?q=searchTerm` via Dio for
  server-side search; Drift `watchAll(searchQuery)` handles local offline search

### 6.3 Gap 2: Patient Notes Sync Path

`SyncQueueProcessor._entityPath('patient_note')` currently returns
`ApiEndpoints.patientNotes` = `/patient-notes/` (wrong URL and wrong pattern).

The actual API is `POST /patients/{patient_id}/notes/` — a **nested path** that requires
the patient's server ID.

**Fix in `SyncQueueProcessor._dispatchApiCall()`:**
```dart
case 'patient_note':
  // Need patient's server_id to build the path
  final notePayload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
  final patientLocalId = notePayload['patient_id'] as String;
  final patientServerId = await _getServerId('patient', patientLocalId);
  if (patientServerId == null) return null;  // wait for patient to sync first
  final resp = await _dio.post<Map<String, dynamic>>(
    ApiEndpoints.patientNotes(patientServerId),
    data: {'content': notePayload['content'], 'local_id': entry.localId},
  );
  return resp.data?['id'] as String?;
```

Remove `patientNotes` from `_entityPath()` switch — it's handled inline above.

### 6.4 Gap 3: Patient History

`GET /patients/{id}/history/` returns the patient's full clinical history.
This is an **online-only** supplementary view — not cached locally.

Add to `patient_repository.dart`:
```dart
Future<PatientHistory> getHistory(String serverId) async {
  final resp = await _dio.get(ApiEndpoints.patientHistory(serverId));
  return PatientHistory.fromJson(resp.data as Map<String, dynamic>);
}
```

---

## 7. Phase 5 — Prescriptions Feature

### 7.1 Current State
- Screens exist: form, detail
- **Drift table:** `Prescriptions` + `PrescriptionItems` ✓
- **DAO:** `PrescriptionDao` ✓
- **Pull sync:** `PullSyncHandler._pullPrescriptions()` ✓ — **but pulls header only, not items**
- **Push sync:** `SyncQueueProcessor` handles `'prescription'` and `'prescription_items'` ✓
- **No** repository, models, or providers

### 7.2 API Contract

| Op | Method | Endpoint | Offline? |
|---|---|---|---|
| Create prescription | POST | `/prescriptions/` | ✅ Queue |
| Get prescription | GET | `/prescriptions/{id}/` | Local read |
| Edit items | PATCH | `/prescriptions/{id}/` | ✅ Queue |
| Pending list | GET | `/prescriptions/pending/` | ❌ Online-only |
| By consultation | GET | `/prescriptions/consultation/{cId}/` | Local read (via consultationId FK) |
| Approve | POST | `/prescriptions/{id}/approve/` | ❌ Online-only |
| Download PDF | GET | `/prescriptions/{id}/pdf/?download=true` | ❌ Online-only (binary) |
| Send | POST | `/prescriptions/{id}/send/` | ❌ Online-only |

### 7.3 Offline-First Write Path

**Create prescription (with items):**
```
1. localId = UUID v4 (prescription)
2. PrescriptionDao.insertPrescription + insertItems (all in one Drift transaction)
   Each item also gets its own UUID localId
3. SyncQueue.enqueue(entityType:'prescription', op:'CREATE', localId, {
     local_id:localId, consultation_id, patient_id,
     items:[{local_id, generic_id?, brand_id?, dosage, frequency,
             duration_days, route, instructions}],
     follow_up_date?
   })
   // Items are bundled in the prescription CREATE payload — no separate item sync ops
4. SyncService.pushSync()
```

> **Key decision:** Send items **bundled** in the prescription CREATE payload (as the API
> `CreatePrescriptionRequest` expects), not as separate sync queue entries. On server response,
> the returned items array maps back to local items by position or `local_id`.

**Edit prescription items:**
```
1. PrescriptionDao.replaceItems(prescriptionId, newItems) in Drift transaction
2. SyncQueue.enqueue(entityType:'prescription', op:'UPDATE', localId, {
     items:[updated items list]
   })
3. SyncService.pushSync()
```

> **Conflict note (ARCHITECTURE.md §1):** Edit uses replace-wholesale (server-wins).
> For v1, this is acceptable if prescriptions are single-doctor-edited.

### 7.4 Pull Sync Gap: Prescription Items

`_pullPrescriptions()` currently syncs prescription headers only. Items must also be pulled.

**Fix in `PullSyncHandler._pullPrescriptions()`:**
```dart
// After upserting prescription headers:
for (final m in rows) {
  final prescLocalId = m['local_id'] as String? ?? m['id'] as String;
  final serverItems = (m['items'] as List<dynamic>?)
      ?.cast<Map<String, dynamic>>() ?? [];
  final itemCompanions = serverItems.map((item) => PrescriptionItemsCompanion.insert(
    id: item['local_id'] as String? ?? item['id'] as String,
    prescriptionId: prescLocalId,
    medicineId: item['brand_id'] as String? ?? item['generic_id'] as String,
    medicineName: item['medicine_name'] as String? ?? '',
    morning: item['morning'] as String? ?? '',
    afternoon: item['afternoon'] as String? ?? '',
    evening: item['evening'] as String? ?? '',
    durationDays: item['duration_days'] as int,
    route: Value(item['route'] as String? ?? 'oral'),
    instructions: Value(item['instructions'] as String? ?? ''),
    lastModified: item['last_modified'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    serverId: Value(item['id'] as String),
    syncStatus: const Value('synced'),
    isDeleted: const Value(0),
  )).toList();
  await _db.prescriptionDao.replaceItems(prescLocalId, itemCompanions);
}
```

> The API's `PrescriptionResponse` already includes `items[]` in the GET response, so
> no extra API call is needed — items come along with the prescription payload.

### 7.5 PDF Download Pattern

```dart
// In prescription_repository.dart
Future<File> downloadPdf(String serverId) async {
  final resp = await _dio.get<List<int>>(
    ApiEndpoints.prescriptionPdf(serverId),
    queryParameters: {'download': 'true'},
    options: Options(responseType: ResponseType.bytes),
  );
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/prescription_$serverId.pdf');
  await file.writeAsBytes(resp.data!);
  return file;  // caller opens with OpenFilex.open(file.path)
}
```

### 7.6 Files to Create

```
lib/features/prescriptions/
  data/
    models/prescription_models.dart   # Prescription, PrescriptionItem,
                                      # CreatePrescriptionRequest, PrescriptionItemInput
    mappers/prescription_mapper.dart
    repositories/prescription_repository.dart
  presentation/
    providers/prescription_providers.dart
```

---

## 8. Phase 6 — Medicines Feature

### 8.1 Current State
- No screens — medicine data is consumed by `PrescriptionFormScreen` autocomplete
- **Drift tables:** `GenericMedicines` + `BrandMedicines` ✓ (lookup tables, no sync columns)
- **DAO:** `MedicineDao` ✓
- **Lookup sync:** `LookupSyncHandler._syncGenericMedicines()` and `_syncBrandMedicines()` ✓
  — but use wrong endpoint paths (fixed in §1.3)

### 8.2 API Contract

| Op | Method | Endpoint | Offline? |
|---|---|---|---|
| Search (autocomplete) | GET | `/medicines/search/?q=&limit=` | Local DB preferred |
| List generics | GET | `/medicines/generics/?search=&drug_class=&limit=&offset=` | Lookup sync |
| Create generic | POST | `/medicines/generics/` | ❌ Online-only (admin) |
| Update generic | PATCH | `/medicines/generics/{id}/` | ❌ Online-only (admin) |
| Delete generic | DELETE | `/medicines/generics/{id}/` | ❌ Online-only (admin) |
| List brands | GET | `/medicines/brands/?search=&generic_id=&form=&active_only=&limit=&offset=` | Lookup sync |
| Create/Update/Delete brand | POST/PATCH/DELETE | `/medicines/brands/[{id}/]` | ❌ Online-only (admin) |
| List manufacturers | GET | `/medicines/manufacturers/` | Lookup sync |
| Create/Update/Delete manufacturer | POST/PATCH/DELETE | `/medicines/manufacturers/[{id}/]` | ❌ Online-only (admin) |

### 8.3 Offline Medicine Search

Medicines are synced to local Drift on app launch (refreshed every 7 days per
`LookupSyncHandler._medicineRefreshInterval`). The `PrescriptionFormScreen` autocomplete
should **first query local Drift** (available offline), and fall back to
`GET /medicines/search/` only when online and the local result is empty.

```dart
// In medicine_repository.dart
Future<List<MedicineSearchResult>> search(String query, {int limit = 20}) async {
  // 1. Search local Drift (always works offline)
  final localResults = await _db.medicineDao.search(query, limit: limit);
  if (localResults.isNotEmpty) return localResults.map(MedicineMapper.fromRow).toList();

  // 2. Fallback to server search when local is empty and online
  if (await _connectivity.isOnline) {
    final resp = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.medicineSearch,
      queryParameters: {'q': query, 'limit': limit},
    );
    return (resp.data!['results'] as List)
        .cast<Map<String, dynamic>>()
        .map(MedicineSearchResult.fromJson)
        .toList();
  }
  return [];
}
```

### 8.4 LookupSyncHandler Fix

After fixing endpoint paths (§1.1), also add manufacturer sync:

```dart
// Add to LookupSyncHandler.syncAll():
Future<void> _syncManufacturers() async {
  // Manufacturers are embedded in brand medicine rows as 'manufacturer' string.
  // If a separate Manufacturers table is added to Drift in future, sync here.
  // For v1: manufacturers are resolved via the brand medicine 'manufacturer' field.
}
```

> The current `BrandMedicines` Drift table stores `manufacturer` as a plain string (not FK).
> The API has a full `Manufacturer` entity with its own CRUD. For v1, keep embedded string.
> Track as a future enhancement if admin screens need manufacturer management.

### 8.5 Files to Create

```
lib/features/medicines/
  data/
    models/medicine_models.dart    # GenericMedicine, BrandMedicine, MedicineSearchResult
    repositories/medicine_repository.dart
  presentation/
    providers/medicine_providers.dart
```

---

## 9. Phase 7 — Billing Feature

### 9.1 Current State
- Screens exist: invoice list, form, detail, add payment
- **Drift tables:** `Invoices`, `InvoiceItems`, `Payments` ✓
- **DAO:** `InvoiceDao` ✓
- **Pull sync:** `PullSyncHandler._pullInvoices()` ✓ — **but pulls headers only, not items or payments**
- **Push sync:** `SyncQueueProcessor` handles `'invoice'`, `'invoice_items'`, `'payment'` ✓
- **No** repository, models, or providers

### 9.2 API Contract

| Op | Method | Endpoint | Offline? |
|---|---|---|---|
| List invoices | GET | `/invoices/` | Pull sync |
| Create invoice | POST | `/invoices/` | ✅ Queue |
| Get invoice detail | GET | `/invoices/{id}/` | Local read (items + payments from Drift) |
| Update status | PATCH | `/invoices/{id}/` | ✅ Queue (status only) |
| Download PDF | GET | `/invoices/{id}/pdf/?download=true` | ❌ Online-only (binary) |
| Record payment | POST | `/payments/` | ✅ Queue |
| Income report | GET | `/income-report/?from_date=&to_date=` | ❌ Online-only |

### 9.3 Offline-First Write Path

**Create invoice (with items):**
```
1. invoiceLocalId = UUID v4
2. For each item: itemLocalId = UUID v4
3. InvoiceDao.insertInvoice + insertItems in one Drift transaction
4. SyncQueue.enqueue(entityType:'invoice', op:'CREATE', invoiceLocalId, {
     local_id: invoiceLocalId,
     patient_id, consultation_id?,
     items:[{local_id, description, quantity, unit_price}],
     discount_percent
   })
   // Items bundled — same pattern as prescriptions
5. SyncService.pushSync()
```

**Record payment:**
```
1. paymentLocalId = UUID v4
2. PaymentDao.insert — invoiceId (local), amount, method, transactionRef, paidAt=now
   syncStatus='pending'
3. SyncQueue.enqueue(entityType:'payment', op:'CREATE', paymentLocalId, {
     local_id: paymentLocalId,
     invoice_id: <invoiceServerId or pending marker>,
     amount, method, transaction_ref
   })
```

> **Payment dependency:** If the invoice hasn't synced yet (no `serverId`),
> `SyncQueueProcessor` must detect this and defer the payment push until the invoice CREATE
> succeeds. Add this guard in `_dispatchApiCall`:
> ```dart
> case 'payment':
>   final invoiceServerId = await _getServerId('invoice', payload['invoice_local_id']);
>   if (invoiceServerId == null) {
>     // Invoice not yet synced — requeue payment behind invoice
>     throw SyncException('Invoice not yet synced', ...);
>   }
>   payload['invoice_id'] = invoiceServerId;
>   // remove invoice_local_id before sending
>   payload.remove('invoice_local_id');
>   final resp = await _dio.post(ApiEndpoints.payments, data: payload);
>   return resp.data?['id'];
> ```

### 9.4 Invoice Total Computation (UI Layer)

Per ARCHITECTURE.md, totals are computed in the UI — not stored:
```
subtotal = Σ(quantity × unit_price)       for all non-deleted invoice_items
total    = subtotal × (1 − discount_percent / 100)
paid     = Σ(amount)                      for all non-deleted payments
balance  = total − paid
```

`InvoiceDao` must provide a stream joining `invoices + invoice_items + payments` by localId.

### 9.5 Pull Sync Gap: Invoice Items + Payments

`_pullInvoices()` currently pulls headers only. Fix:

```dart
// In _pullInvoices(), after upserting headers:
for (final m in rows) {
  final invLocalId = m['local_id'] as String? ?? m['id'] as String;

  // Upsert items
  final items = (m['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
  await _db.invoiceDao.replaceItems(invLocalId, items.map(...).toList());

  // Upsert payments
  final payments = (m['payments'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
  await _db.invoiceDao.upsertPayments(invLocalId, payments.map(...).toList());
}
```

> The API's `InvoiceDetail` schema already includes `items[]` and `payments[]`, so these
> are returned in the list response (confirm with backend — list may return `InvoiceSummary`
> which excludes items; detail endpoint `GET /invoices/{id}/` returns `InvoiceDetail`).
> If list returns summary only, fetch details lazily on `_pullInvoices`.

### 9.6 Files to Create

```
lib/features/billing/
  data/
    models/billing_models.dart    # Invoice, InvoiceItem, Payment, InvoiceSummary,
                                  # InvoiceDetail, CreateInvoiceRequest, RecordPaymentRequest,
                                  # IncomeReport
    mappers/billing_mapper.dart
    repositories/billing_repository.dart
  presentation/
    providers/billing_providers.dart
```

---

## 10. Phase 8 — Test Orders Feature

### 10.1 Current State
- Screens exist: list, form
- **Drift table:** `TestOrders` ✓
- **DAO:** `TestOrderDao` ✓
- **Pull sync:** `PullSyncHandler._pullTestOrders()` ✓
- **Push sync:** `SyncQueueProcessor` handles `'test_order'` ✓
- **No** repository, models, or providers

### 10.2 API Contract

| Op | Method | Endpoint | Offline? |
|---|---|---|---|
| List for consultation | GET | `/consultations/{cId}/test-orders/` | Local read (FK filter) |
| Bulk create | POST | `/consultations/{cId}/test-orders/` | ✅ Queue (special path) |
| List for patient | GET | `/test-orders/?patient_id=&pending_only=` | Pull sync |
| My test orders | GET | `/test-orders/mine/` | ❌ Online-only |
| Pending test orders | GET | `/test-orders/pending/` | ❌ Online-only |
| Update test order | PATCH | `/test-orders/{id}/` | ✅ Queue |
| Delete test order | DELETE | `/test-orders/{id}/` | ✅ Queue (soft delete) |

### 10.3 Offline-First Write Path

**Bulk create test orders:**
```
1. For each order: localId = UUID v4, insert TestOrdersCompanion into Drift
2. SyncQueue.enqueue(entityType:'test_order_bulk', op:'CREATE',
     localId: consultationLocalId,   // group key
     payload: {
       consultation_id: <consultationServerId or pending>,
       orders: [
         {local_id, test_name, lab_name, notes},
         ...
       ]
     }
   )
3. SyncService.pushSync()
```

> `'test_order_bulk'` is a new entity type in `_entityPath()` → `ApiEndpoints.consultationTestOrders(consultationServerId)`.
> Wait for consultation to sync before pushing (same dependency pattern as payments → invoices).
> On server response, map returned item IDs back to local rows by `local_id`.

**Update / delete test order:**
- Standard `UPDATE` / `DELETE` ops against `ApiEndpoints.testOrderDetail(serverId)`

### 10.4 Files to Create

```
lib/features/test_orders/
  data/
    models/test_order_models.dart    # TestOrder, CreateTestOrderRequest,
                                     # UpdateTestOrderRequest, BulkCreateTestOrderRequest
    mappers/test_order_mapper.dart
    repositories/test_order_repository.dart
  presentation/
    providers/test_order_providers.dart
```

---

## 11. Phase 9 — Reports Feature

### 11.1 Current State
- Screens exist: list, upload
- **No Drift table** — reports are not cached locally (per ARCHITECTURE.md: `report_documents.file_binary` excluded)
- **No** DAO, repository, models, or providers

### 11.2 API Contract

| Op | Method | Endpoint | Offline? |
|---|---|---|---|
| List reports | GET | `/reports/` | ❌ Online-only |
| Upload report | POST | `/reports/` (multipart) | Queued via `FileUploadQueue` |
| Delete report | DELETE | `/reports/{id}/` | ❌ Online-only |
| Stream file | GET | `/reports/{id}/file/` | ❌ Online-only (binary) |

### 11.3 Upload Flow (FileUploadQueue)

Reports use `FileUploadQueue` — not `SyncQueue` — because file uploads are large and must
not block record sync.

**Fix `FileUploadQueue._upload()`** — update wrong endpoint:
```dart
// Change:   ApiEndpoints.reportDocuments  →  ApiEndpoints.reports
await _dio.post<void>(ApiEndpoints.reports, data: formData);
```

Also add `consultation_id` to the upload payload (currently missing):
```dart
final formData = FormData.fromMap({
  'patient_id':      upload.patientId,
  'category':        upload.category,
  if (upload.consultationId != null) 'consultation_id': upload.consultationId,
  if (upload.testOrderId != null)    'test_order_id':   upload.testOrderId,
  if (upload.notes != null)          'notes':           upload.notes,
  'file': await MultipartFile.fromFile(upload.localPath,
              filename: File(upload.localPath).uri.pathSegments.last),
});
```

**Offline upload behaviour:**
1. User picks file → `FileUploadQueue.enqueue(...)` is called
2. If offline: file stays in-memory queue with `retryCount=0`
3. When `SyncService` detects connectivity restored → call `FileUploadQueue._processNext()`
4. Max retries: 3. After 3 failures → surface error to user (no silent discard)

### 11.4 File Streaming Pattern

```dart
// In report_repository.dart
Future<File> downloadReportFile(String reportId) async {
  final resp = await _dio.get<List<int>>(
    ApiEndpoints.reportFile(reportId),
    options: Options(responseType: ResponseType.bytes),
  );
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/report_$reportId');
  await file.writeAsBytes(resp.data!);
  return file;
}
```

### 11.5 No Drift Table Needed

Per ARCHITECTURE.md, report binaries are never cached. `ReportResponse` metadata
(id, patient_id, category, file_url, original_filename, uploaded_by_name, uploaded_at,
notes) is fetched fresh each time.

### 11.6 Files to Create

```
lib/features/reports/
  data/
    models/report_models.dart        # ReportResponse, UploadReportRequest
    repositories/report_repository.dart
  presentation/
    providers/report_providers.dart
```

---

## 12. Phase 10 — Chambers & Doctors (Lookup Data)

### 12.1 Current State
- Chamber list screen exists
- **Drift tables:** `Chambers`, `DoctorProfiles`, `Specialities` ✓ (lookup, no sync columns)
- **DAOs:** `ChamberDao`, `DoctorProfileDao`, `SpecialityDao` ✓
- **Lookup sync:** `LookupSyncHandler` syncs all three ✓ — but **wrong endpoint paths** (fixed §1.3)
- **No** repositories, models, or providers

### 12.2 API Contract

#### Chambers
| Op | Method | Endpoint | Offline? |
|---|---|---|---|
| List | GET | `/chambers/` | Lookup sync (full list) |
| Create | POST | `/chambers/` | ❌ Online-only (admin) |
| Update | PATCH | `/chambers/{id}/` | ❌ Online-only (admin) |
| Delete | DELETE | `/chambers/{id}/` | ❌ Online-only (admin) |

#### Doctor Profiles & Specialities
| Op | Method | Endpoint | Offline? |
|---|---|---|---|
| List specialities | GET | `/specialities/?active_only=` | Lookup sync |
| List doctor profiles | GET | `/doctors/profiles/?user_id=&speciality_id=&is_available=&search=` | Lookup sync |
| List doctors (users) | GET | `/users/doctors/` | Lookup sync (via `_syncUsers()`) |
| CRUD (admin) | POST/PATCH/DELETE | various | ❌ Online-only |

### 12.3 Lookup Sync is Already Wired

After fixing endpoint paths in §1.3, `LookupSyncHandler` handles all chamber and doctor data.
Screens read from Drift streams:
- `ChamberDao.watchAll()` → chamber picker in appointment form
- `DoctorProfileDao.watchAll()` → doctor picker
- `SpecialityDao.watchAll()` → speciality filter

### 12.4 Files to Create

```
lib/features/chambers/
  data/
    models/chamber_models.dart       # Chamber, CreateChamberRequest
    repositories/chamber_repository.dart
  presentation/
    providers/chamber_providers.dart

lib/features/doctors/               # new feature directory
  data/
    models/doctor_models.dart        # DoctorProfile, Speciality
    repositories/doctor_repository.dart
  presentation/
    providers/doctor_providers.dart
```

---

## 13. Phase 11 — Dashboard & Analytics

### 13.1 Current State
- Screens exist: `dashboard_screen.dart`, `analytics_screen.dart`
- **No** data layer

### 13.2 API Contract

| Op | Method | Endpoint | Response |
|---|---|---|---|
| Dashboard stats | GET | `/dashboard/` | Aggregate counts (today's appointments, consultations, revenue, queue length, etc.) |
| Income report | GET | `/income-report/?from_date=&to_date=` | Time-series revenue data for charts |

### 13.3 Online-Only Pattern

Both are online-only reads with no local cache.

```dart
// dashboard_providers.dart
@riverpod
class DashboardNotifier extends _$DashboardNotifier {
  @override
  Future<DashboardStats> build() => _fetchStats();

  Future<DashboardStats> _fetchStats() async {
    final resp = await _dio.get<Map<String, dynamic>>(ApiEndpoints.dashboard);
    return DashboardStats.fromJson(resp.data!);
  }

  Future<void> refresh() => ref.refresh(dashboardNotifierProvider.future);
}
```

`DashboardScreen` shows a stale-data banner when offline (last refresh timestamp shown).

### 13.4 Files to Create

```
lib/features/dashboard/
  data/
    models/dashboard_models.dart     # DashboardStats, IncomeReport, IncomeDataPoint
    repositories/dashboard_repository.dart
  presentation/
    providers/dashboard_providers.dart
```

---

## 14. Phase 12 — User Management & Audit Logs (Admin)

### 14.1 Current State
- `settings_screen.dart` exists (partial)
- **Drift table:** `Users` ✓ (lookup — synced via `LookupSyncHandler._syncUsers()`)
- **No** admin repository or providers

### 14.2 API Contract

#### User Management
| Op | Method | Endpoint | Offline? |
|---|---|---|---|
| List users | GET | `/users/` | Lookup sync |
| Create user | POST | `/users/` | ❌ Online-only |
| Get user | GET | `/users/{id}/` | Local read (from Drift) |
| Update user | PATCH | `/users/{id}/` | ❌ Online-only |
| Deactivate user | DELETE | `/users/{id}/` | ❌ Online-only |

#### Audit Logs
| Op | Method | Endpoint | Offline? |
|---|---|---|---|
| List audit logs | GET | `/audit-logs/?action=&resource_type=&user_id=&date_from=&date_to=&page=&page_size=` | ❌ Online-only |

Per ARCHITECTURE.md: `audit_log.*` is server-side only, never synced down.

### 14.3 Files to Create

```
lib/features/settings/
  data/
    models/user_admin_models.dart    # StaffUser, CreateUserRequest, UpdateUserRequest
    models/audit_log_models.dart     # AuditLog, AuditLogListResponse
    repositories/user_admin_repository.dart
    repositories/audit_log_repository.dart
  presentation/
    providers/settings_providers.dart
```

---

## 15. SyncQueueProcessor — Complete Entity Map

After all phases, `_entityPath()` and `_dispatchApiCall()` must handle:

| `entityType` string | Push operation | API endpoint pattern | Notes |
|---|---|---|---|
| `patient` | CREATE/UPDATE/DELETE | `/patients/` or `/patients/{serverId}/` | ✓ exists |
| `patient_note` | CREATE | `/patients/{patientServerId}/notes/` | Nested path — handle inline, not in `_entityPath()` |
| `appointment` | CREATE/UPDATE/DELETE | `/appointments/` or `/appointments/{serverId}/` | ✓ exists |
| `walk_in` | CREATE only | `/appointments/walk-in/` | Add to `_entityPath()` |
| `consultation` | CREATE/UPDATE/DELETE | `/consultations/` or `/consultations/{serverId}/` | ✓ exists |
| `consultation_vitals` | UPDATE only | `/consultations/{serverId}/vitals/` | Dynamic path — handle inline |
| `prescription` | CREATE/UPDATE | `/prescriptions/` or `/prescriptions/{serverId}/` | ✓ exists; items bundled in payload |
| `test_order_bulk` | CREATE only | `/consultations/{consultationServerId}/test-orders/` | Dynamic path — handle inline; wait for consultation sync |
| `test_order` | UPDATE/DELETE | `/test-orders/{serverId}/` | ✓ exists |
| `invoice` | CREATE/UPDATE | `/invoices/` or `/invoices/{serverId}/` | ✓ exists; items bundled |
| `payment` | CREATE only | `/payments/` | ✓ exists; wait for invoice sync |

**Entities that do NOT use SyncQueue (online-only):**
- `auth/*` — login, logout, refresh, change-password
- `consultation_complete` — `POST /consultations/{id}/complete/`
- `appointment_checkin` — `POST /appointments/{id}/check-in/`
- `appointment_status` — `PATCH /appointments/{id}/status/`
- `prescription_approve` — `POST /prescriptions/{id}/approve/`
- `prescription_send` — `POST /prescriptions/{id}/send/`

---

## 16. PullSyncHandler — Complete Pull Map

`pullSync()` must cover all mutable entities. Extend `Future.wait([...])`:

```dart
Future<void> pullSync() async {
  final isoTs = _getDeltaTimestamp();  // null on first sync

  await Future.wait([
    _pullPatients(isoTs),        // GET /patients/search/ (fix §6.2)
    _pullAppointments(isoTs),    // GET /appointments/
    _pullConsultations(isoTs),   // GET /consultations/  (includes vitals)
    _pullPrescriptions(isoTs),   // GET /prescriptions/  (fix §7.4: include items)
    _pullTestOrders(isoTs),      // GET /test-orders/
    _pullInvoices(isoTs),        // GET /invoices/       (fix §9.5: include items + payments)
  ]);

  await _prefs.setLastSyncTimestamp(DateTime.now().millisecondsSinceEpoch);
}
```

**Soft-delete handling** in every `_pullX()`:
```dart
// After upsert, check is_deleted flag:
if ((m['is_deleted'] as bool?) == true) {
  await _db.patientDao.softDelete(localId);  // sets is_deleted=1, deleted_at=now
}
```

---

## 17. LookupSyncHandler — Complete Lookup Map

After path fixes, `syncAll()` covers:

```dart
Future<void> syncAll() async {
  await Future.wait([
    _syncChambers(),       // GET /chambers/
    _syncUsers(),          // GET /users/
    _syncSpecialities(),   // GET /specialities/
    _syncDoctorProfiles(), // GET /doctors/profiles/  ← fix path
  ]);
  await _syncMedicinesIfStale();
  // _syncGenericMedicines(): GET /medicines/generics/  ← fix path
  // _syncBrandMedicines():   GET /medicines/brands/    ← fix path
  await _prefs.setLookupLastSync(DateTime.now().millisecondsSinceEpoch);
}
```

---

## 18. Background Sync (WorkManager)

`BackgroundSyncTask` already runs every 15 minutes via WorkManager. It calls
`PullSyncHandler.pullSync()` + `SyncQueueProcessor.pushSync()` — this is correct.

**What to verify:**
- `LookupSyncHandler` is NOT called in background sync (lookup data is only refreshed on app launch / manual pull-to-refresh — lookup tables change rarely and 7-day staleness is acceptable)
- The background task's `DioClient.create()` uses `AppConfig.current.baseUrl` — ensure port is updated to 8005 (fixed in §1.1)
- WorkManager constraint `networkType: NetworkType.connected` ensures background sync only runs when online

---

## 19. FileUploadQueue — Connectivity Trigger

Currently `FileUploadQueue` processes uploads eagerly. Add a connectivity hook so queued
uploads are retried when connectivity is restored:

```dart
// In SyncService.initialize():
_connectivitySub = _connectivity.onConnectivityChanged.listen((isOnline) {
  if (isOnline && !_isSyncing) {
    unawaited(pushSync());
    _fileUploadQueue.retryPending();  // ← add this
  }
});
```

Add `retryPending()` to `FileUploadQueue`:
```dart
void retryPending() {
  if (_queue.isNotEmpty && !_isProcessing) _processNext();
}
```

---

## 20. Additional Drift Indexes to Add

Per ARCHITECTURE.md recommendation, add these after initial schema is stable:

```sql
-- Unsynced record sweep (for SyncQueueProcessor)
CREATE INDEX IF NOT EXISTS idx_patients_sync     ON patients(sync_status)     WHERE is_deleted = 0;
CREATE INDEX IF NOT EXISTS idx_appointments_sync ON appointments(sync_status) WHERE is_deleted = 0;
CREATE INDEX IF NOT EXISTS idx_consultations_sync ON consultations(sync_status) WHERE is_deleted = 0;
CREATE INDEX IF NOT EXISTS idx_prescriptions_sync ON prescriptions(sync_status) WHERE is_deleted = 0;
CREATE INDEX IF NOT EXISTS idx_test_orders_sync   ON test_orders(sync_status)   WHERE is_deleted = 0;
CREATE INDEX IF NOT EXISTS idx_invoices_sync       ON invoices(sync_status)      WHERE is_deleted = 0;

-- Queue view: chamber + date compound
CREATE INDEX IF NOT EXISTS idx_appt_chamber_date
  ON appointments(chamber_id, scheduled_at, status);

-- Prescription items per prescription (already exists — verify)
CREATE INDEX IF NOT EXISTS idx_prescription_items_prescription
  ON prescription_items(prescription_id);

-- Invoice items per invoice
CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice ON invoice_items(invoice_id);

-- Payments per invoice
CREATE INDEX IF NOT EXISTS idx_payments_invoice ON payments(invoice_id);
```

Add these to `AppDatabase._createIndexes()`.

---

## 21. Implementation Order & Priority

| Priority | Phase | Blocker | Est. complexity |
|---|---|---|---|
| **P0** | §1 — Fix endpoints + base URL | Everything | Low (edit one file) |
| **P0** | §1.2 — Confirm delta-sync with backend | Pull sync efficiency | Requires backend decision |
| **P1** | §3 — Auth (login/logout/me/token refresh) | All auth-gated screens | Medium |
| **P1** | §6.2–6.3 — Patient pull path + notes sync | Core data correctness | Low (fix 2 methods) |
| **P1** | §4 — Appointments (book, walk-in, queue, SSE) | Core clinical workflow | High |
| **P1** | §5 — Consultations (start, draft, vitals, complete) | Core clinical workflow | High |
| **P2** | §7 — Prescriptions (create, items sync, PDF) | Depends on consultations | High |
| **P2** | §8 — Medicines (search, lookup sync fix) | Depends on prescriptions | Low (fix paths, add search) |
| **P2** | §9 — Billing (invoice, items sync, payment) | Depends on consultations | High |
| **P3** | §10 — Test orders (bulk create, dependency chain) | Depends on consultations | Medium |
| **P3** | §11 — Reports (upload fix, file streaming) | Standalone | Medium |
| **P3** | §12 — Chambers & Doctors (path fix only) | Lookup sync fix | Low |
| **P4** | §13 — Dashboard & Analytics | Online-only, standalone | Low |
| **P4** | §14 — User management & Audit logs | Admin-only, online-only | Low |

---

## 22. Per-Feature File Creation Checklist

For each mutable feature, create these files following the **patients** feature pattern:

```
lib/features/<feature>/
  data/
    models/<feature>_models.dart
      ├─ @freezed domain model (mirrors Drift table columns)
      ├─ @freezed CreateXRequest
      └─ @freezed UpdateXRequest
    mappers/<feature>_mapper.dart
      ├─ static T fromRow(XRow row)               ← Drift row → domain model
      ├─ static XCompanion toCreateCompanion(...)  ← request → Drift write
      └─ static XCompanion toUpdateCompanion(...)  ← request → Drift update
    repositories/<feature>_repository.dart
      ├─ abstract IXRepository (interface)
      └─ class XRepository implements IXRepository
          ├─ Stream<List<X>> watchAll(...)          ← Drift stream
          ├─ Future<X?> getById(String localId)     ← Drift read
          ├─ Future<void> createX(CreateXRequest)   ← Drift write + enqueue + pushSync
          ├─ Future<void> updateX(UpdateXRequest)   ← Drift update + enqueue + pushSync
          └─ Future<void> deleteX(String localId)   ← soft delete + enqueue + pushSync
  presentation/
    providers/<feature>_providers.dart
      ├─ @riverpod XRepository xRepository(...)
      ├─ @riverpod Stream<List<X>> xList(...)       ← watches repository
      └─ @riverpod class XNotifier extends _$XNotifier  ← mutation state
```

For **online-only** features (dashboard, audit logs, reports): skip mapper, repository reads
from Dio directly, no SyncQueue involvement.

---

## 23. API-to-Screen Mapping (Complete)

| Screen | APIs consumed | Offline? |
|---|---|---|
| `LoginScreen` | `POST /auth/login/` | ❌ |
| `DashboardScreen` | `GET /dashboard/` | ❌ (shows cached stats when offline) |
| `PatientListScreen` | `watchAll()` from Drift; `GET /patients/search/` (server fallback) | ✅ |
| `PatientDetailScreen` | Drift stream; `GET /patients/{id}/history/` | ✅ (history offline shows empty) |
| `PatientFormScreen` | `createPatient()` / `updatePatient()` via repo | ✅ |
| `AppointmentListScreen` | `watchByDate()` from Drift | ✅ |
| `AppointmentFormScreen` | `createAppointment()` / `updateAppointment()` via repo | ✅ |
| `AppointmentDetailScreen` | Drift stream; `POST /check-in/`; `PATCH /status/` | ✅ read / ❌ actions |
| `QueueManagementScreen` | `GET /appointments/queue/`; SSE `/queue/stream/` | ❌ |
| `ConsultationFormScreen` | `createConsultation()`; `updateDraft()`; `recordVitals()`; `POST /complete/` | ✅ write / ❌ complete |
| `ConsultationDetailScreen` | Drift stream | ✅ |
| `PrescriptionFormScreen` | `createPrescription()`; `MedicineRepo.search()` | ✅ |
| `PrescriptionDetailScreen` | Drift stream; `POST /approve/`; `GET /pdf/`; `POST /send/` | ✅ read / ❌ actions |
| `InvoiceListScreen` | `watchAll()` from Drift | ✅ |
| `InvoiceFormScreen` | `createInvoice()` via repo | ✅ |
| `InvoiceDetailScreen` | Drift stream; `GET /pdf/` | ✅ read / ❌ PDF |
| `AddPaymentScreen` | `recordPayment()` via repo | ✅ (queued) |
| `TestOrderListScreen` | Drift stream; `GET /test-orders/pending/` | ✅ local / ❌ pending |
| `TestOrderFormScreen` | `createBulkTestOrders()` via repo | ✅ |
| `ReportListScreen` | `GET /reports/`; `GET /reports/{id}/file/` | ❌ |
| `ReportUploadScreen` | `FileUploadQueue.enqueue()` | ✅ (queued) |
| `ChamberListScreen` | `ChamberDao.watchAll()` from Drift | ✅ |
| `AnalyticsScreen` | `GET /income-report/` | ❌ |
| `SettingsScreen` | `GET /auth/me/`; `PATCH /auth/me/`; `POST /change-password/`; `GET /users/`; `GET /audit-logs/` | ❌ |
