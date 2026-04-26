# Runbook: New Feature

→ [Back to runbooks](README.md)

Use this for any new screen, entity, or significant code change. For production crashes, use [Incident Response](incident-response.md) instead.

---

## Stage 1 — Plan

1. Run the architect agent (`.claude/agents/architect.md`) with a feature brief
2. Plan output must include:
   - Data model (new Drift tables or columns)
   - Component list (screens, providers, DAOs)
   - API endpoints used
   - Any PHI (patient health information) touch points
3. Save plan to `.claude/scratch/plan-<feature>.md`
4. Resolve all open questions before proceeding

**Gate 1 check:** all questions answered, file list complete, PHI identified (or explicitly none)

---

## Stage 2 — Implement

### If adding a new Drift table

1. Define the table in `core/database/tables/<entity>_tables.dart`
   - Include all 5 sync columns (`serverId`, `syncStatus`, `isDeleted`, `deletedAt`, `lastModified`)
2. Register in `AppDatabase` `@DriftDatabase(tables: [...])`
3. Add DAO: `core/database/daos/<entity>_dao.dart`
   - Read methods must return `Stream<List<...>>`
   - Every query must filter `isDeleted.equals(false)`
4. Update `AppDatabase.wipeAll()` — add `delete(newTable).go()`
5. Update `AppDatabase._createIndexes()` — add FK indexes
6. Wire sync:
   - `SyncQueueProcessor._entityPath()` — new entity type string
   - `SyncQueueProcessor._getServerId()` — new entity
   - `SyncQueueProcessor._updateServerId()` — new entity
   - `PullSyncHandler._pullX()` — new pull method
7. **Run code generation** (see [codegen.md](codegen.md))

### If adding a feature model

1. Create `features/<name>/data/models/<name>_model.dart` with `@freezed` + `@JsonSerializable`
2. Create `features/<name>/data/mappers/<name>_mapper.dart`
3. Run code generation

### If adding screens

1. Create screens under `features/<name>/presentation/screens/`
2. Register routes in `core/config/router_config.dart`
3. Reference `features/patients/` for the canonical pattern

---

## Stage 3 — Review

Pass changed files to the reviewer agent. Address all BLOCKER and HIGH issues before proceeding.

**Gate 3 check:** reviewer verdict is APPROVED or APPROVED WITH NOTES; all blockers resolved

---

## Stage 4 — Test

```bash
cd medidesk

# Static checks
flutter analyze

# Widget tests
flutter test
```

Manual checks (both iOS and Android):
- [ ] Feature reachable from correct entry point
- [ ] Works completely offline (no crash, no blank screen)
- [ ] Online sync round-trip: create offline → go online → verify server received it
- [ ] Soft-delete: deleted records do not appear after restart
- [ ] No regression in login, patient list, appointment list flows

---

## Stage 5 — Ship

```bash
git add <specific files>
git commit -m "feat: <description>"
```

PR title format: `feat: <short description ≤ 70 chars>`

PR body must state: "This PR does not touch PHI" **OR** describe exactly what PHI is accessed and how it is handled.

---

## Offline-First Checklist (final gate)

Before opening the PR, confirm every item:

- [ ] Table has all 5 sync columns
- [ ] DAO reads return `Stream<List<...>>`
- [ ] Every DAO query filters `isDeleted == 0`
- [ ] Repository writes Drift before enqueuing to SyncQueue
- [ ] SyncQueueProcessor handles the new entity type
- [ ] PullSyncHandler pulls the new entity
- [ ] `AppDatabase.wipeAll()` includes the new table
- [ ] Code generation is current (no stale `.g.dart` files)
- [ ] `flutter analyze` exits clean

---

## See Also

- [Offline-First Architecture](../architecture/offline-first.md) — invariants explained
- [Code Generation](codegen.md) — when and how to run build_runner
- `.claude/workflows/feature.md` — full agent-orchestrated pipeline
