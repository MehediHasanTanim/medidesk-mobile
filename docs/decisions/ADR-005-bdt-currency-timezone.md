# ADR-005: BDT Currency and Asia/Dhaka Timezone Handling

**Status:** Accepted  
**Date:** 2025-01-01

---

## Context

MediDesk targets clinics in Bangladesh. Two locale-specific concerns needed explicit decisions:

1. **Currency:** Bangladesh Taka (BDT, ৳). No VAT or tax in the v1 clinic billing context. Sub-unit (poisha) is rarely used in clinical billing.
2. **Timezone:** Bangladesh is UTC+6 with no daylight saving time. All devices are expected to be in this timezone, but the server stores everything in UTC.

---

## Decision

**Currency:**  
All monetary values are stored as `REAL` in Drift with no tax columns. Display is handled exclusively by `DateFormatter.formatBdt(amount)` → `৳ 1,250.00`. Invoice totals are computed at render time (never stored).

**Timezone:**  
All timestamps are stored as UTC ISO 8601 strings in Drift. Conversion to local time happens **only** in `core/utils/date_formatter.dart` using the `timezone` package (`Asia/Dhaka`). `tz.initializeTimeZones()` is called in `main()` before `runApp`.

---

## Consequences

**Easier:**
- Single conversion point (`DateFormatter`) means timezone bugs are isolated to one file
- UTC storage survives DST rule changes (there are none for Dhaka, but this is a safe default)
- No tax logic in v1 simplifies billing calculations significantly

**Harder / ruled out:**
- Adding tax in a future version requires a schema migration (new `tax_rate` column on invoices) and a UI update — the current invoice total formula does not account for tax
- Multi-timezone support (e.g., if the product expands to India or Pakistan) requires parameterizing `DateFormatter._dhaka` — it is currently hardcoded
- Sub-unit (paisa) precision is not supported; amounts rounded to 2 decimal places
- If a clinic operates outside `Asia/Dhaka`, the developer must change `_dhaka` in `DateFormatter` — there is no runtime config for this in v1
