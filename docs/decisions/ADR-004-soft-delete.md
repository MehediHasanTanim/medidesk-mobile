# ADR-004: Soft-Delete Everywhere — No Hard Deletes

**Status:** Accepted  
**Date:** 2025-01-01

---

## Context

MediDesk operates in an offline-first environment where multiple devices may sync independently. A hard `DELETE` on one device cannot be propagated reliably to other devices during a delta-sync pull — the record simply disappears from the server's response, and the receiving device has no way to distinguish "record I haven't pulled yet" from "record that was deleted".

The server backend (Django REST Framework) also needs to notify devices of deletions through the delta-sync mechanism (`?updated_after=<ts>`).

---

## Decision

All mutable tables use **soft-delete**: deletions set `is_deleted = 1` and `deleted_at = <UTC timestamp>`. No `DELETE` SQL is issued against mutable tables. The server mirrors this policy.

---

## Consequences

**Easier:**
- Delta pulls can include deleted records (`is_deleted: true`) so every device learns about deletions during its next sync
- Accidental deletes are recoverable (admin operation on the server)
- Audit trail: `deleted_at` provides a timestamp for every deletion
- Conflict resolution is unambiguous: a delete is just another field update subject to `last_modified` ordering

**Harder / ruled out:**
- Every DAO query **must** apply `WHERE is_deleted = 0` — omitting this filter silently shows deleted records in the UI
- Database rows are never purged; storage grows indefinitely unless a separate server-side purge policy runs for records deleted more than N days ago
- Restoring a deleted record requires a server-side admin action (no in-app undelete UI in v1)

**Enforcement:**  
The `.claude/hooks/validate-dao-patterns.sh` hook warns when a DAO query lacks an `isDeleted` filter.
