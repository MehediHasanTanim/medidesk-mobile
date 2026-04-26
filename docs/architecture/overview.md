# Architecture Overview

→ [Back to docs](../README.md)

## Stack

| Concern | Choice | Version |
|---------|--------|---------|
| Language | Dart | SDK ^3.5.0 |
| Framework | Flutter | ≥ 3.24 |
| State management | Riverpod 2 + riverpod_generator | 2.5.1 |
| Local database | Drift (SQLite) + drift_dev codegen | 2.20 |
| Navigation | go_router | 14 |
| HTTP | Dio + 3 interceptors | 5 |
| Background sync | WorkManager (15-min periodic) | 0.9 |
| Forms | reactive_forms | 17 |
| Code generation | freezed + json_serializable + riverpod_generator | single pass |
| Secure storage | flutter_secure_storage | 9 |

---

## Module Map

```
lib/
├── core/
│   ├── config/       AppConfig (env URLs), RouterConfig (go_router)
│   ├── database/     Drift tables, DAOs, AppDatabase, converters
│   ├── enums/        AppEnums — all Dart enums live here
│   ├── error/        AppException (sealed), ErrorHandler
│   ├── network/      DioClient + auth/error/logging interceptors, ApiEndpoints
│   ├── storage/      SecureStorageService, PreferencesService
│   ├── sync/         SyncService, PullSyncHandler, SyncQueueProcessor,
│   │                 LookupSyncHandler, FileUploadQueue, ConflictResolver,
│   │                 BackgroundSyncTask (WorkManager entry point)
│   ├── theme/        AppTheme, AppColors, AppTextStyles
│   └── utils/        DateFormatter, Validators, Extensions, IsolateHelper
│
├── features/
│   ├── patients/     ← COMPLETE — canonical offline-first slice
│   │   ├── data/
│   │   │   ├── mappers/   patient_mapper.dart
│   │   │   └── models/    patient_model.dart (.freezed.dart, .g.dart)
│   │   └── presentation/screens/
│   └── (others)/     Stub screens — must follow patients/ pattern
│
├── shared/
│   ├── providers/    connectivity_provider, sync_status_provider,
│   │                 infrastructure_providers (injectable singletons)
│   └── widgets/      OfflineBanner, SyncStatusBadge, AppButton, ...
│
└── main.dart         ProviderScope overrides, WorkManager init, tz init
```

---

## Feature Implementation Status

| Feature | Status | Notes |
|---------|--------|-------|
| `patients/` | Complete | Reference implementation |
| `appointments/` | Stub screens | Implement following patients/ |
| `consultations/` | Stub screens | Implement following patients/ |
| `prescriptions/` | Stub screens | Implement following patients/ |
| `billing/` | Stub screens | Implement following patients/ |
| `analytics/` | Stub screen | Read-only, no sync queue needed |
| `chambers/` | Stub screen | Lookup-only (no push sync) |
| `auth/` | Login screen | Token auth wired |

---

## Entry Point (`main.dart`)

Three things happen before `runApp`:
1. `tz.initializeTimeZones()` — timezone data must be available before any date display
2. `Workmanager().initialize(callbackDispatcher)` — registers the background sync task
3. `ProviderScope` overrides inject `AppDatabase`, `DioClient`, and storage singletons

---

## See Also

- [Offline-First Invariants](offline-first.md) — required patterns for every new entity
- [Sync System](sync-system.md) — how data moves between device and server
- [API Contract](api-contract.md) — backend endpoint assumptions
