---
name: Database Index Reference
description: Existing and recommended Drift indexes for query performance
type: project
---

## Already Created in `AppDatabase._createIndexes()`

| Table | Index | Purpose |
|---|---|---|
| `sync_queue` | `(status, next_retry_at, created_at)` | FIFO pending-item fetch |
| `patients` | `full_name`, `phone`, `patient_id` | Free-text search |
| `appointments` | `(scheduled_at, status)` | Day-view list |
| `appointments` | `(patient_id, scheduled_at)` | Patient history |
| `appointments` | `(doctor_id, scheduled_at)` | Doctor schedule |
| `consultations` | `(patient_id, created_at)` | Patient timeline |
| `prescriptions` | `patient_id` | Active prescriptions lookup |
| `prescription_items` | `prescription_id` | Item fetch per prescription |
| `test_orders` | `patient_id`, `ordered_at` | Patient test history |
| `invoices` | `(created_at, status)` | Invoice dashboard |
| `invoices` | `patient_id` | Patient billing |

## Recommended — Add as Data Grows

```sql
-- Unsynced record sweep (background sync)
CREATE INDEX idx_patients_sync ON patients(sync_status) WHERE is_deleted = 0;
CREATE INDEX idx_appointments_sync ON appointments(sync_status) WHERE is_deleted = 0;

-- Chamber + date compound (queue view)
CREATE INDEX idx_appt_chamber_date ON appointments(chamber_id, scheduled_at, status);

-- Brand medicine FTS (if SQLite FTS5 available — consider Drift VirtualTable + fts5 for >50k rows)
```
