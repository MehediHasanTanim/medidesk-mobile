---
name: MediDesk Mobile — Project Overview
description: Core identity, stack, and scope of the MediDesk Flutter app
type: project
---

**MediDesk** is an offline-first clinic management mobile app built in Flutter/Dart.
It targets BD (Bangladesh) clinics and syncs with a Django REST Framework backend.

**Stack:**
- Flutter ≥3.24, Dart SDK ^3.5.0
- State: Riverpod 2 + riverpod_generator (`@riverpod` annotations)
- Local DB: Drift 2.20 (SQLite) with code-gen DAOs
- Navigation: go_router 14
- HTTP: Dio 5 with 3 interceptors (auth, error, logging)
- Background sync: WorkManager (15-min periodic)
- Forms: reactive_forms
- Code-gen: freezed + json_serializable + riverpod_generator — all run in ONE build_runner pass

**Key constraints:**
- Currency: BDT (৳), no tax in v1. Stored as REAL, displayed via `DateFormatter.formatBdt()`
- Timezone: Asia/Dhaka (UTC+6, no DST). Only `DateFormatter` does UTC→local conversion
- All timestamps stored as UTC ISO 8601 strings in Drift
- RBAC enforced server-side only; app uses `role` field only

**Feature status (as of project setup):**
- `features/patients/` — COMPLETE (reference implementation for offline-first slice)
- All other features — stub screens; must follow the `patients/` pattern

**Why:** Offline-first clinic workflow where internet is unreliable; sync happens in background.
**How to apply:** When implementing new features, always treat `patients/` as the canonical reference.
