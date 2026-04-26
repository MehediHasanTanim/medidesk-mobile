# MediDesk Skills — Execution Engine

Each skill encodes one repeatable capability for this project.
Reference them by name when starting a task.

| Skill | File | When to use |
|---|---|---|
| `new-feature` | [new-feature.md](new-feature.md) | Scaffold a complete offline-first feature slice (model → mapper → repo → providers → screens → sync registration) |
| `code-review` | [code-review.md](code-review.md) | Review code against offline-first invariants, Riverpod conventions, and sync patterns |
| `debug-sync` | [debug-sync.md](debug-sync.md) | Diagnose stuck sync queues, missing serverIds, pull failures, conflict rollbacks |
| `debug-dart` | [debug-dart.md](debug-dart.md) | Fix Dart/Flutter compile errors, Riverpod exceptions, Drift SQLite errors, null safety |
| `refactor` | [refactor.md](refactor.md) | Restructure code safely without breaking offline-first invariants or generated files |
| `build-codegen` | [build-codegen.md](build-codegen.md) | Run build_runner, fix codegen errors, verify generated output |
| `release-check` | [release-check.md](release-check.md) | Full pre-release checklist: analyze, tests, invariants, config, conflict decisions |

## Update Policy

When a skill fails or a better pattern is found:
1. Edit the relevant skill file
2. Add a one-line note to `.claude/memory/MEMORY.md` under "Patterns that worked / Mistakes"

Skills encode **what we know works** — keep them honest.
