---
name: Development Workflow & Code-Gen
description: Build commands, code generation, and generated-file conventions
type: project
---

## Code Generation (single pass)

Always run from `medidesk/` directory:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

During active development use watch mode:
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

## What Gets Generated

| Package | Input | Output |
|---|---|---|
| `drift_dev` | `*.dart` tables + `@DriftDatabase` | `app_database.g.dart`, `*_dao.g.dart` |
| `freezed` | `@freezed` classes | `*.freezed.dart` |
| `json_serializable` | `@JsonSerializable` | `*.g.dart` |
| `riverpod_generator` | `@riverpod` / `class X extends _$X` | `*_providers.g.dart` |

All generated files (`*.g.dart`, `*.freezed.dart`) are git-ignored — never edit them manually.

## API Base URL

Configured via `AppConfig.current.baseUrl` → e.g. `https://api.medidesk.app/api/v1`
All endpoint paths in `core/network/api_endpoints.dart`.

## Dependency Override

`pubspec.yaml` has: `analyzer_plugin: ">=0.13.0 <0.15.0"` — this is intentional, do not remove.
