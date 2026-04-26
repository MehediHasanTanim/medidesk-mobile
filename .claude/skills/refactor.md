# Skill: refactor
**Refactor MediDesk code without breaking offline-first invariants**

Use when the user asks to clean up, restructure, rename, or extract code.

---

## Pre-Refactor Checklist (read before touching anything)

1. **Identify all generated files** — `.g.dart` and `.freezed.dart` are auto-generated. Never edit them.
   If the source file changes, regenerate: `flutter pub run build_runner build --delete-conflicting-outputs`

2. **Check if the target is used in sync infrastructure** — before renaming an `entityType` string,
   verify it appears in:
   - `SyncQueueProcessor._entityPath()`
   - `SyncQueueProcessor._getServerId()`
   - `SyncQueueProcessor._updateServerId()`
   - `PullSyncHandler` pull methods
   - Any existing `sync_queue` records in production DB (renaming breaks in-flight records)

3. **DAO method signature changes** — if a DAO read method changes from `Stream` to `Future` for any reason, that is a breaking change. DAO reads must always return `Stream<...>`.

4. **Mapper is `abstract final`** — do not add constructors or instance state to mappers.

---

## Safe Refactor Patterns

### Extract a widget
- Move UI code from a screen to `features/<name>/presentation/widgets/<widget_name>.dart`
- Pass data down via constructor — do not lift state into the widget (use the existing provider)
- No business logic in widgets; all mutations go through Riverpod notifiers

### Rename a domain field
1. Update the `@freezed` class in `<name>_model.dart`
2. Update the mapper (`fromRow`, `toCreateCompanion`, `toUpdateCompanion`)
3. Update the DAO and table if the DB column name changes
4. Run build_runner
5. Fix all compile errors via `flutter analyze`
6. If the field name in the API payload changes, update the JSON serialisation helpers in the repository

### Split a large DAO
- Keep the `@DriftAccessor(tables: [...])` annotation on each partial DAO
- Register all DAOs in `@DriftDatabase(daos: [...])` in `app_database.dart`
- Run build_runner after

### Extract shared logic to a utility
- Put in `core/utils/` if it's used across features
- Put in `features/<name>/` if it's feature-specific
- No side effects in utilities — pure functions only

---

## Refactor Anti-Patterns (don't do these)

| Anti-pattern | Why it's wrong |
|---|---|
| Changing `Stream` DAO reads to `Future` | Breaks reactive UI — Riverpod stream providers won't update |
| Moving Drift write after sync enqueue | Violates offline-first invariant — data must exist locally before queuing |
| Removing `isDeleted == 0` filter to "simplify" a query | Surfaces soft-deleted records in the UI |
| Inlining mapper logic into the repository | Loses the clean separation; mapper must be testable in isolation |
| Using `ref.read()` in a widget's `build()` | Bypasses reactivity — only use `ref.watch()` in build |
| Storing computed invoice totals in DB | Totals are always computed in the UI layer |

---

## Post-Refactor Steps (always run)

```bash
cd medidesk

# Regenerate if any annotated file changed
flutter pub run build_runner build --delete-conflicting-outputs

# Must be clean — zero errors, zero warnings
flutter analyze

# Run tests if they exist
flutter test
```

Report the results. If `flutter analyze` has warnings, fix them before declaring done.
