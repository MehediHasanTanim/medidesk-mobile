# ADR-001: Drift (SQLite) as Local Database

**Status:** Accepted  
**Date:** 2025-01-01

---

## Context

MediDesk must work fully offline — in Bangladesh clinics, internet drops frequently during patient visits. The app needs a local database that can:

1. Persist structured relational data (patients, appointments, consultations, invoices)
2. Support reactive streams so the UI updates when local data changes
3. Integrate with a code-generation pipeline (the project already uses `build_runner` for Riverpod and Freezed)
4. Support complex queries: joins, delta-sync timestamps, soft-delete filters

Options considered: **Drift**, Hive, ObjectBox, Isar, raw SQLite via `sqflite`.

---

## Decision

Use **Drift 2.x** (formerly Moor) with `drift_dev` code generation for all local persistence.

---

## Consequences

**Easier:**
- Strongly typed SQL queries — the compiler catches query errors
- `Stream<List<T>>` return type on all DAOs — UI rebuilds automatically on any local write
- Single `build_runner` pass generates DAOs, converters, and database migration stubs alongside Riverpod and Freezed
- SQLite gives relational integrity (foreign keys, indexed queries) needed for the invoice → items relationship

**Harder / ruled out:**
- Schema migrations require explicit `MigrationStrategy` — every column add or table rename needs a migration step
- Generated files (`*.g.dart`, `*_dao.g.dart`) must never be hand-edited; `build_runner` must be re-run after any schema change
- No document-style storage — all data must be normalized into tables

**Dependency override required:**  
`pubspec.yaml` includes `analyzer_plugin: ">=0.13.0 <0.15.0"` to satisfy `drift_dev`'s analyzer version requirement. Do not remove this override.
