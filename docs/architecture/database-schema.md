# Database Schema

→ [Back to docs](../README.md)

Local database: **Drift 2.20 (SQLite)**. Schema is defined in Dart table classes; `drift_dev` generates the typed query layer.

---

## Soft-Delete Contract

All mutable tables use soft-delete. Hard deletes are **never** used.

| Action | Implementation |
|--------|---------------|
| Delete a record | Set `isDeleted = 1`, `deletedAt = <UTC ISO 8601>` |
| Read records | Always filter `WHERE is_deleted = 0` |
| Sync delete to server | `DELETE /entity/<server_id>/` — server mirrors soft-delete |
| Receive server delete | Delta pull returns record with `is_deleted: true`; app upserts locally |

---

## Mandatory Columns (every mutable table)

```dart
TextColumn  get serverId    => text().nullable()();
TextColumn  get syncStatus  => text().withDefault(const Constant('pending'))();
IntColumn   get isDeleted   => integer().withDefault(const Constant(0))();
TextColumn  get deletedAt   => text().nullable()();
IntColumn   get lastModified => integer()();   // Unix epoch ms
```

The hooks enforcement layer (`guard-drift-table`) will warn if any of these are missing.

---

## Timestamp Storage

All timestamps are stored as **UTC ISO 8601 strings** in Drift `TextColumn` fields.  
Conversion to `Asia/Dhaka` (UTC+6) happens **only** in `core/utils/date_formatter.dart`.  
Never store local time; never convert outside `DateFormatter`.

---

## Indexes — Active

Registered in `AppDatabase._createIndexes()`:

| Table | Index columns | Query served |
|-------|--------------|-------------|
| `sync_queue` | `(status, next_retry_at, created_at)` | FIFO pending-item fetch |
| `patients` | `full_name`, `phone`, `patient_id` | Free-text search |
| `appointments` | `(scheduled_at, status)` | Day-view list |
| `appointments` | `(patient_id, scheduled_at)` | Patient history |
| `appointments` | `(doctor_id, scheduled_at)` | Doctor schedule |
| `consultations` | `(patient_id, created_at)` | Patient timeline |
| `prescriptions` | `patient_id` | Active prescriptions |
| `prescription_items` | `prescription_id` | Items per prescription |
| `test_orders` | `patient_id`, `ordered_at` | Patient test history |
| `invoices` | `(created_at, status)` | Invoice dashboard |
| `invoices` | `patient_id` | Patient billing |

---

## Indexes — Recommended (add as data grows)

```sql
-- Unsynced record sweep (background sync hot path)
CREATE INDEX idx_patients_sync ON patients(sync_status) WHERE is_deleted = 0;
CREATE INDEX idx_appointments_sync ON appointments(sync_status) WHERE is_deleted = 0;

-- Chamber + date compound (queue view)
CREATE INDEX idx_appt_chamber_date ON appointments(chamber_id, scheduled_at, status);
```

For medicine search at > 50k rows, consider Drift `VirtualTable` + SQLite FTS5 extension.

---

## Fields Excluded from Mobile

These server-side fields are intentionally absent from the Drift schema:

| Field | Reason |
|-------|--------|
| `users.password_hash`, `last_login`, `permissions` | Auth is token-only; RBAC is server-side |
| `doctor_profiles.rating`, `clinic_registration_no` | Future feature / compliance PDF only |
| `patients.photo_url` | File caching not in v1 |
| `report_documents.file_binary` | Display via `file_url`; no local cache |
| `prescriptions.digital_signature` | Requires PKI; deferred to v2 |
| `invoices.tax_amount` | No tax in BD clinic context (v1) |
| `payments.cheque_date` | Cheque method not in v1 |
| `audit_log.*` | Server-side only |
| `notification_settings.*` | Push notifications deferred to v2 |

---

## Currency

Monetary values are `REAL` (BDT, 2 decimal places). Never stored with tax or rounding adjustments.

Invoice totals are **computed in the UI layer** — not stored:

```
subtotal = Σ(quantity × unit_price)  // non-deleted items only
total    = subtotal × (1 − discount_percent / 100)
paid     = Σ(amount)                 // non-deleted payments only
balance  = total − paid
```

Display via `DateFormatter.formatBdt(amount)` → `৳ 1,250.00`

---

## See Also

- [Offline-First](offline-first.md) — full new-entity checklist
- [ADR-001](../decisions/ADR-001-drift-local-db.md) — why Drift was chosen
- [ADR-004](../decisions/ADR-004-soft-delete.md) — why soft-delete everywhere
