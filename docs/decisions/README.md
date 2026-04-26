# Architecture Decision Records

ADRs capture the *why* behind non-obvious decisions. They are not design documents — they are permanent records of choices made and the context that drove them.

→ [Back to docs](../README.md)

---

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-001](ADR-001-drift-local-db.md) | Drift (SQLite) as local database | Accepted |
| [ADR-002](ADR-002-server-wins-sync.md) | Server-wins conflict resolution | Accepted (with open items) |
| [ADR-003](ADR-003-riverpod-codegen.md) | Riverpod 2 + code generation for state | Accepted |
| [ADR-004](ADR-004-soft-delete.md) | Soft-delete everywhere — no hard deletes | Accepted |
| [ADR-005](ADR-005-bdt-currency-timezone.md) | BDT currency and Asia/Dhaka timezone handling | Accepted |

---

## Template

```markdown
# ADR-NNN: Title

**Status:** Proposed | Accepted | Superseded by ADR-NNN
**Date:** YYYY-MM-DD

## Context
What situation forced a decision? What constraints existed?

## Decision
What was decided, in one or two sentences.

## Consequences
What becomes easier? What becomes harder or is explicitly ruled out?
```

Rules:
- One decision per ADR
- Context explains the situation *at the time* — don't revise history
- Consequences list trade-offs honestly, including what is now harder
- Status "Superseded" links to the newer ADR; don't delete old records
