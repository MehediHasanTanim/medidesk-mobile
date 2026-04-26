# Skill: build-codegen
**Run code generation and verify all output is correct**

Use when: adding a new `@freezed` class, `@riverpod` provider, `@DriftDatabase` table or DAO,
after a merge conflict in generated files, or when the app fails to compile due to missing `.g.dart` parts.

---

## When to Run

| Trigger | Action |
|---|---|
| New `@freezed` class | `build_runner build` |
| New `@riverpod` / `class X extends _$X` | `build_runner build` |
| New Drift table or `@DriftAccessor` DAO | `build_runner build` |
| `.g.dart` file missing or stale | `build_runner build --delete-conflicting-outputs` |
| Merge conflict in a `.g.dart` file | Delete conflicted file, then `build_runner build` |
| Switching branches with schema changes | `build_runner build --delete-conflicting-outputs` |

---

## Commands

Always run from the `medidesk/` directory:

```bash
# First time or after conflicts — safest
flutter pub run build_runner build --delete-conflicting-outputs

# During active development — watches for file changes
flutter pub run build_runner watch --delete-conflicting-outputs

# If pub cache is stale
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
```

---

## What Gets Generated

| Generator | Input annotation | Output file |
|---|---|---|
| `freezed` | `@freezed class Foo` | `foo.freezed.dart` |
| `json_serializable` | `@JsonSerializable` | `foo.g.dart` |
| `riverpod_generator` | `@riverpod` / `class X extends _$X` | `foo_providers.g.dart` |
| `drift_dev` | `@DriftDatabase` / `@DriftAccessor` | `app_database.g.dart`, `*_dao.g.dart` |

All generated files are git-ignored. Never edit them manually.

---

## Common Build Failures and Fixes

### `part directive` error
```
Error: Can't find source for part 'foo.g.dart'
```
Fix: the `part 'foo.g.dart';` declaration is present but build_runner hasn't run yet.
Run `build_runner build`.

### Conflicting outputs
```
[SEVERE] Found N declared outputs which already exist on disk
```
Fix: always use `--delete-conflicting-outputs` flag.

### `analyzer_plugin` version conflict
This project has `dependency_overrides: analyzer_plugin: ">=0.13.0 <0.15.0"` — do not remove this override.
If build fails with analyzer version errors, check this override is still in `pubspec.yaml`.

### `@DriftAccessor` tables mismatch
```
Error: Table X referenced in @DriftAccessor but not included in @DriftDatabase
```
Fix: add the table to `@DriftDatabase(tables: [...])` in `app_database.dart`.

### Missing `_$ClassName` mixin (freezed)
The `with _$ClassName` mixin is generated — if it's missing after build, check that `part 'foo.freezed.dart';`
is declared in the source file.

---

## Verification Steps After Build

```bash
# Should show zero errors
flutter analyze

# Optional — run tests
flutter test
```

Check that all `part` files resolve:
```bash
# Should find no unresolved part references
grep -r "part '" medidesk/lib --include="*.dart" | grep -v ".g.dart" | grep -v ".freezed.dart"
```

---

## Watch Mode for Development

During active feature development, keep watch mode running in a separate terminal:
```bash
cd medidesk
flutter pub run build_runner watch --delete-conflicting-outputs
```

Watch mode regenerates only changed files — much faster than a full build.
