# Skill: release-check
**Pre-release checklist for MediDesk Mobile**

Use before cutting a release build or tagging a version.

---

## Phase 1 — Code Quality

```bash
cd medidesk

# Regenerate all code
flutter pub run build_runner build --delete-conflicting-outputs

# Must be zero errors
flutter analyze

# Run tests
flutter test
```

All three must pass cleanly. Do not proceed with any errors.

---

## Phase 2 — Offline-First Invariants Audit

For every mutable entity (patients, appointments, consultations, prescriptions,
prescription_items, test_orders, invoices, invoice_items, payments):

- [ ] Drift table has: `server_id`, `sync_status`, `is_deleted`, `deleted_at`, `last_modified`
- [ ] DAO reads all return `Stream<...>`
- [ ] All mutations: Drift write → sync enqueue → `pushSync()`
- [ ] Every DAO query has `isDeleted == 0` filter
- [ ] Entity type registered in `SyncQueueProcessor._entityPath()`
- [ ] `PullSyncHandler` has `_pull<Entity>()` implemented
- [ ] `AppDatabase.wipeAll()` clears every mutable table

Quick check:
```bash
# Find any Future<List> reads in DAOs (should return zero hits if clean)
grep -r "Future<List" medidesk/lib/core/database/daos/

# Find queries missing isDeleted filter
grep -r "select\|watch" medidesk/lib/core/database/daos/ | grep -v "isDeleted"
```

---

## Phase 3 — Sync Conflict Decisions

The following conflict cases are **unresolved** as of project setup.
Confirm with the product owner whether any of these are in-scope for this release:

- [ ] `prescription_items` — server-wins wholesale or merge-by-ID? (Current: wholesale — silent data loss risk)
- [ ] `invoice_items` — same decision as prescription_items
- [ ] `consultation` vitals — concurrent edit by doctor + nurse (Current: server-wins drops one)
- [ ] `appointment.status` — forward-only transitions implemented? (Current: server-wins can roll back)

If any of these are in-scope, do NOT ship without an explicit product decision.

---

## Phase 4 — Configuration

- [ ] `AppConfig.current.baseUrl` points to the correct production URL (not localhost or staging)
- [ ] `logging_interceptor.dart` — verbose HTTP logging disabled in release mode
- [ ] `debugShowCheckedModeBanner: false` in `MediDeskApp` (already set in `main.dart`)
- [ ] `flutter_secure_storage` is used for tokens — not `SharedPreferences`
- [ ] `WorkManager` background sync registered with correct task name and constraints

```bash
# Check for any hardcoded localhost URLs
grep -r "localhost\|127.0.0.1\|10.0.2.2" medidesk/lib/

# Check logging is guarded
grep -r "kDebugMode\|kReleaseMode" medidesk/lib/core/network/interceptors/logging_interceptor.dart
```

---

## Phase 5 — Build

```bash
# Android release
flutter build apk --release
# or
flutter build appbundle --release

# iOS release (requires Xcode signing configured)
flutter build ipa --release
```

---

## Phase 6 — Excluded Fields Audit

Confirm none of these server-side fields appear in any DTO or are sent to the client:
`password_hash`, `last_login`, `permissions`, `groups`, `rating`, `clinic_registration_no`,
`photo_url`, `file_binary`, `digital_signature`, `tax_amount`, `cheque_date`, `audit_log`, `notification_settings`

```bash
grep -r "password_hash\|digital_signature\|tax_amount\|audit_log" medidesk/lib/
```

Should return no hits.

---

## Phase 7 — Sign-Off

Report the results as:

```
## Release Check: v<version>

### PASS
- flutter analyze: clean
- flutter test: N tests passed
- Offline-first invariants: verified
- Config: production URL confirmed
- Excluded fields: none found

### BLOCKED (list any fails)
- ...

### OPEN DECISIONS (need product sign-off before shipping)
- prescription_items conflict resolution
- ...
```
