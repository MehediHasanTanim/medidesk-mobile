# MediDesk Mobile — Documentation

Offline-first clinic management app. Flutter/Dart · Drift · Riverpod 2 · Django REST backend.

---

## Architecture

| Doc | What it covers |
|-----|---------------|
| [Overview](architecture/overview.md) | Stack, module map, feature status, directory layout |
| [Offline-First](architecture/offline-first.md) | Core invariants and new-entity checklist |
| [Sync System](architecture/sync-system.md) | Push/pull/background sync, open conflict decisions |
| [Database Schema](architecture/database-schema.md) | Mandatory columns, soft-delete, indexes |
| [API Contract](architecture/api-contract.md) | REST endpoints, delta-sync pattern, file upload |

---

## Decisions (ADRs)

| ADR | Decision |
|-----|----------|
| [ADR-001](decisions/ADR-001-drift-local-db.md) | Drift (SQLite) as local database |
| [ADR-002](decisions/ADR-002-server-wins-sync.md) | Server-wins conflict resolution |
| [ADR-003](decisions/ADR-003-riverpod-codegen.md) | Riverpod 2 + code generation for state |
| [ADR-004](decisions/ADR-004-soft-delete.md) | Soft-delete everywhere — no hard deletes |
| [ADR-005](decisions/ADR-005-bdt-currency-timezone.md) | BDT currency + Asia/Dhaka timezone handling |

→ [ADR template and index](decisions/README.md)

---

## Runbooks

| Runbook | When to use |
|---------|-------------|
| [New Feature](runbooks/new-feature.md) | Implementing any new offline-first feature |
| [Code Generation](runbooks/codegen.md) | Running build_runner after schema/model changes |
| [Release](runbooks/release.md) | Building and submitting to App Store / Play Store |
| [Incident Response](runbooks/incident-response.md) | Production crash, data loss, security issue |

→ [Runbook index](runbooks/README.md)

---

## Quick Links

- Source: `medidesk/lib/` — app code
- Canonical feature reference: `medidesk/lib/features/patients/`
- Detailed architecture reference: `medidesk/ARCHITECTURE.md`
- Workflows (plan → build → review → test → ship): `.claude/workflows/`
