# Runbook: Code Generation

→ [Back to runbooks](README.md)

MediDesk uses a single `build_runner` pass for three code-generation packages. Run this after any change to a table definition, DAO, model, or provider.

---

## When to Run

| You changed... | Re-run needed? |
|----------------|---------------|
| A Drift table (`core/database/tables/*.dart`) | Yes |
| A DAO annotation (`@DriftAccessor`) | Yes |
| `AppDatabase` table list or `@DriftDatabase` | Yes |
| A `@freezed` model class | Yes |
| A `@JsonSerializable` class | Yes |
| A `@riverpod` provider class | Yes |
| A UI widget or screen with no annotations | No |
| A `*.g.dart` or `*.freezed.dart` file directly | Never — these are outputs |

The `.claude/hooks/suggest-codegen.sh` hook reminds you automatically when relevant files are written.

---

## Commands

All commands run from `medidesk/` (the Flutter project root).

### One-time build

```bash
cd medidesk
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

`--delete-conflicting-outputs` resolves stale generated files. Always use it.

### Watch mode (active development)

```bash
cd medidesk
flutter pub run build_runner watch --delete-conflicting-outputs
```

Watches for file changes and regenerates automatically. Use during active schema or model work.

---

## What Gets Generated

| Package | Input annotation | Output file |
|---------|-----------------|-------------|
| `drift_dev` | Table classes + `@DriftDatabase` | `app_database.g.dart`, `*_dao.g.dart` |
| `freezed` | `@freezed` | `*.freezed.dart` |
| `json_serializable` | `@JsonSerializable` | `*.g.dart` |
| `riverpod_generator` | `@riverpod` / `class X extends _$X` | `*_providers.g.dart` |

---

## Generated File Rules

- All generated files end in `.g.dart` or `.freezed.dart`
- **Never edit them manually** — changes are overwritten on the next build
- They are git-ignored — do not commit them
- The `.claude/hooks/guard-generated-files.sh` hook blocks accidental edits

---

## Troubleshooting

**`build_runner` fails with a conflict error**  
Always use `--delete-conflicting-outputs`. If it still fails, delete the `.dart_tool/build` cache:
```bash
rm -rf .dart_tool/build
flutter pub run build_runner build --delete-conflicting-outputs
```

**"Unknown identifier" compile error after a schema change**  
Generated files are stale. Re-run build_runner.

**`analyzer_plugin` version conflict**  
`pubspec.yaml` contains a required override: `analyzer_plugin: ">=0.13.0 <0.15.0"`. Do not remove it — `drift_dev` requires this range. See [ADR-001](../decisions/ADR-001-drift-local-db.md).

**Watch mode is not picking up a new file**  
Stop watch mode, run a one-time build, then restart watch mode.

---

## See Also

- [ADR-001](../decisions/ADR-001-drift-local-db.md) — why Drift + build_runner
- [ADR-003](../decisions/ADR-003-riverpod-codegen.md) — why Riverpod code generation
- [Database Schema](../architecture/database-schema.md) — what tables must define
