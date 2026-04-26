# ADR-002: Server-Wins Conflict Resolution

**Status:** Accepted (with open items — see below)  
**Date:** 2025-01-01

---

## Context

When a device edits a record offline and the server has a newer version of the same record, one value must be chosen. The app needs a deterministic, implementable policy that handles the common case correctly without requiring a complex merge UI.

The target users are clinic receptionists and doctors. Concurrent editing of the *same* record by two people at once is rare (one patient at a time). The larger risk is a stale device overwriting recent server changes.

---

## Decision

**Server wins** when the server record's `last_modified` timestamp is newer than the local record's `last_modified`. The server value is written to Drift and the local pending change is discarded.

---

## Consequences

**Easier:**
- No conflict UI needed — users never see a merge dialog
- Deterministic and auditable — `last_modified` timestamps are authoritative
- Simple to implement and test

**Harder / ruled out:**
- Concurrent edits by two users on different devices will silently drop one user's change
- Forward-only state transitions (e.g., `appointment.status`) can be incorrectly reversed

---

## Open Items (require product decision before shipping)

These specific cases are **not** covered correctly by the default server-wins policy. Each needs an explicit product decision logged here before the affected feature ships.

| Entity | Problem | Status |
|--------|---------|--------|
| `prescription_items` | Replace-wholesale drops offline additions | Undecided |
| `invoice_items` | Same as prescription_items | Undecided |
| `consultation` vitals | Concurrent doctor/nurse edit drops one update | Undecided |
| `appointment.status` | Server-wins can reverse a forward transition | Undecided |
| `patient_note` | Append-only — no conflict possible | ✅ Safe |

See [Sync System — Open Conflict Decisions](../architecture/sync-system.md#open-conflict-decisions--require-product-input) for the specific options for each case.
