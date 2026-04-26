# Skill: debug-dart
**Diagnose and fix Dart/Flutter compilation and runtime errors in MediDesk**

Use when: the app fails to compile, a widget throws at runtime, a provider
throws `ProviderException`, or `flutter analyze` reports errors.

---

## Step 1 — Classify the Error

| Error type | Signals |
|---|---|
| Build / codegen | `part directive`, `_$ClassName not found`, `*.g.dart missing` |
| Riverpod | `ProviderException`, `ref.watch called outside build`, `StateError from AsyncValue` |
| Drift / DB | `SqliteException`, `DatabaseException`, `Invalid companion` |
| Type mismatch | `type 'X' is not a subtype of 'Y'` |
| Null safety | `Null check operator used on null value` |
| Async misuse | `setState called after dispose`, `unawaited future` |

---

## Step 2 — Codegen Errors

If the error mentions `.g.dart`, `.freezed.dart`, or `_$ClassName`:

```bash
cd medidesk
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
```

If build_runner itself errors:
- Check `pubspec.yaml` has `analyzer_plugin: ">=0.13.0 <0.15.0"` under `dependency_overrides`
- Run `flutter pub get` first, then build_runner

---

## Step 3 — Riverpod Errors

**`ProviderException` or `AsyncError` in UI:**
- The notifier's `state = await AsyncValue.guard(...)` caught an exception
- Read the inner exception from `state.error` or the error log
- Trace back to the repository method — which DAO or network call threw?

**`ref.watch called outside build`:**
- `ref.watch()` is in a callback/event handler. Replace with `ref.read()` for one-shot reads

**Provider not rebuilding after DB change:**
- Confirm the DAO method returns `Stream<...>` (not `Future<List>`)
- Confirm the Riverpod provider uses `@riverpod Stream<...>` (not `@riverpod Future<List>`)

**`StateNotifierProviderElement` disposed:**
- A notifier was used after the widget tree disposed it
- Ensure `ref.read()` (not `ref.watch()`) is used in fire-and-forget async calls

---

## Step 4 — Drift / SQLite Errors

**`SqliteException(1): table has no column named X`:**
- Schema changed but migration was not added
- In development: delete the app and reinstall (or call `AppDatabase.wipeAll()`)
- Before shipping: add a `MigrationStrategy` in `AppDatabase`

**`Invalid companion — required field missing`:**
- A non-nullable column has no default and was not provided in `.insert()`
- Check `toCreateCompanion` in the mapper — all non-nullable, non-defaulted columns must be set

**`isDeleted` column not found in query:**
- Table definition is missing `BoolColumn get isDeleted => boolean().withDefault(const Constant(false))()`
- Regenerate after adding the column

---

## Step 5 — Null Safety / Type Errors

**`Null check operator used on null value` in mapper:**
- A `row.someField!` where `someField` is nullable and actually null
- Replace with null-aware access or add a default: `row.someField ?? ''`

**`type 'String' is not a subtype of 'int'` from JSON:**
- A `@JsonSerializable` field type doesn't match the server response
- Add a custom converter or update the freezed model field type

**`List<dynamic>` from `jsonDecode`:**
- Always cast: `List<String>.from(jsonDecode(raw) as List)`
- See `PatientMapper._parseJsonList()` for the safe pattern

---

## Step 6 — Async Misuse

**`setState called after dispose`:**
- An async callback completed after the widget unmounted
- Use `if (mounted)` guard before `setState`, or move state to a Riverpod provider

**`unawaited future` lint:**
- Either add `await` or wrap with `unawaited(...)` from `dart:async` to make intent explicit
- In repositories, `unawaited(_syncService.pushSync())` is intentional — keep the import

---

## Step 7 — Verify Fix

```bash
flutter analyze          # must be clean
flutter test             # run tests if they exist
flutter run --debug      # smoke test the affected screen
```

State the root cause, the fix applied, and the verification result.
