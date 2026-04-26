# Skill: new-feature
**Scaffold a complete offline-first feature slice**

Use when the user asks to implement a new feature (appointments, billing, consultations, etc.).
The canonical reference implementation is `features/patients/`.

---

## Input Required

Before writing any code, confirm:
- Entity name (singular, e.g. `appointment`)
- Fields and their types
- Whether it is mutable (needs sync) or lookup-only (read-only, synced by LookupSyncHandler)

---

## Execution Steps

### 1. Domain Model — `features/<name>/data/models/<name>_model.dart`

- Use `@freezed` for all classes
- Domain entity must include sync fields: `serverId`, `syncStatus` (default `'pending'`), `isDeleted` (default `false`), `deletedAt`
- Add `Create<Name>Request` and `Update<Name>Request` freezed classes (no sync fields)
- Add `factory <Name>.fromJson(Map<String, dynamic> json) => _$<Name>FromJson(json);`

```dart
@freezed
class MyEntity with _$MyEntity {
  const factory MyEntity({
    required String id,          // local UUID
    // ... domain fields ...
    required int lastModified,   // ms since epoch (UTC)
    String? serverId,
    @Default('pending') String syncStatus,
    @Default(false) bool isDeleted,
    String? deletedAt,
  }) = _MyEntity;
  factory MyEntity.fromJson(Map<String, dynamic> json) => _$MyEntityFromJson(json);
}
```

### 2. Mapper — `features/<name>/data/mappers/<name>_mapper.dart`

- `abstract final class <Name>Mapper`
- `static <Name> fromRow(<Name>Row row)` — maps Drift row → domain model
- `static <Name>sCompanion toCreateCompanion(String localId, Create<Name>Request req)`
  - Sets `createdAt` and `updatedAt` to `DateTime.now().toUtc().toIso8601String()`
  - Sets `lastModified` to `DateTime.now().millisecondsSinceEpoch`
  - Sets `syncStatus: const Value('pending')`, `isDeleted: const Value(0)`
- `static <Name>sCompanion toUpdateCompanion(Update<Name>Request req)`
  - Only updates changed fields + `updatedAt`, `lastModified`, `syncStatus`

### 3. Repository — `features/<name>/data/repositories/<name>_repository.dart`

Follow the `PatientRepository` pattern exactly:
- Abstract interface `I<Name>Repository` with all public methods
- Constructor injects `AppDatabase db` and `SyncService syncService`
- **Read methods return `Stream<...>` (never `Future<List>`)** — map through DAO then mapper
- **Mutation order (mandatory):**
  1. Write to Drift via DAO (optimistic)
  2. Enqueue to `SyncQueueCompanion.insert(...)` with `entityType: '<name>'`
  3. `unawaited(_syncService.pushSync())`
- Soft-delete: call `dao.softDelete(localId)`, enqueue `operation: 'DELETE'`
- All payloads include `'local_id': localId` in the JSON map

### 4. Providers — `features/<name>/presentation/providers/<name>_providers.dart`

```dart
part '<name>_providers.g.dart';

// Repository
final <name>RepositoryProvider = Provider<...>((ref) {
  return <Name>Repository(
    db: ref.watch(appDatabaseProvider),
    syncService: ref.watch(syncServiceProvider),
  );
});

// Stream provider (reactive list)
@riverpod
Stream<List<MyEntity>> <name>List(<Name>ListRef ref) {
  return ref.watch(<name>RepositoryProvider).watchAll();
}

// Mutation notifiers
@riverpod
class Create<Name>Notifier extends _$Create<Name>Notifier {
  @override
  FutureOr<void> build() {}
  Future<void> execute(Create<Name>Request req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(<name>RepositoryProvider).create<Name>(req));
  }
}
// ... Update, Delete notifiers follow same pattern
```

### 5. Register with Sync Infrastructure

Open these 4 files and add the new entity:

| File | What to add |
|---|---|
| `core/sync/sync_queue_processor.dart` | Case in `_entityPath()`, `_getServerId()`, `_updateServerId()` |
| `core/sync/pull_sync_handler.dart` | `_pull<Name>()` method + call it from `pullAll()` |
| `core/database/app_database.dart` | `delete(<name>Table).go()` in `wipeAll()`; indexes in `_createIndexes()` |
| `core/database/daos/<name>_dao.dart` | DAO with `watchAll()` returning `Stream`, `softDelete()`, `insertBatch()` |

### 6. Screens (stub if UI not specified)

```
features/<name>/presentation/screens/
  <name>_list_screen.dart    — ConsumerWidget, watches <name>ListProvider
  <name>_form_screen.dart    — ConsumerStatefulWidget, uses Create/Update notifiers
  <name>_detail_screen.dart  — ConsumerWidget, watches single entity stream
```

### 7. Register Route

Add route in `core/config/router_config.dart` following the pattern of existing routes.

### 8. Code Generation

After all files are written:
```bash
cd medidesk
flutter pub run build_runner build --delete-conflicting-outputs
```

Then run `flutter analyze` and fix all warnings before declaring done.

---

## Checklist Before Marking Complete

- [ ] Domain model has `serverId`, `syncStatus`, `isDeleted`, `deletedAt`, `lastModified`
- [ ] All DAO reads return `Stream<...>`
- [ ] Drift write happens BEFORE sync enqueue in every mutation
- [ ] `SyncQueueProcessor` handles the new `entityType`
- [ ] `PullSyncHandler` has `_pull<Name>()`
- [ ] `AppDatabase.wipeAll()` clears the table
- [ ] Soft-delete filter `isDeleted == 0` in every DAO query
- [ ] `build_runner` ran without errors
- [ ] `flutter analyze` clean
