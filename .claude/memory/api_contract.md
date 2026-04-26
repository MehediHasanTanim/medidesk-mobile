---
name: REST API Contract
description: Django backend endpoint assumptions the mobile app is built against
type: project
---

Base URL: `AppConfig.current.baseUrl` (e.g. `https://api.medidesk.app/api/v1`)

## Auth Endpoints

| Method | Path | Notes |
|---|---|---|
| POST | `/auth/token/` | `{username, password}` → `{access, refresh, user: {id, role, ...}}` |
| POST | `/auth/token/refresh/` | `{refresh}` → `{access}` |
| POST | `/auth/logout/` | `{refresh}` → 204 |
| GET | `/auth/me/` | → `UserRow` |

## Lookup (read-only, no pagination except medicines)

- `/chambers/`, `/users/`, `/specialities/`, `/doctor-profiles/` — flat list
- `/medicines/generic/?page=N&limit=500` — paginated `{results, next, count}`
- `/medicines/brand/?page=N&limit=500` — paginated

## Mutable Resources (delta-sync)

All support `?updated_after=<ISO8601 UTC>` + `?limit=500`.
Response: `{ results, next, count }`.

Entities: `/patients/`, `/appointments/`, `/consultations/`, `/prescriptions/`,
`/prescription-items/`, `/test-orders/`, `/invoices/`, `/invoice-items/`, `/payments/`

- POST includes `"local_id": "<uuid>"` — server MUST echo it in 201 response
- DELETE = soft-delete: server sets `is_deleted=true`, `deleted_at=<timestamp>`
- Deleted records appear in delta pulls with `"is_deleted": true`

## File Upload

`POST /report-documents/` multipart/form-data:
- `file` (binary), `patient_id` (UUID), `category` (blood_test|imaging|biopsy|other)
- Optional: `test_order_id`, `notes`
- Response: `{ id, patient_id, category, file_url, created_at, ... }`

## Fields Intentionally Excluded from Mobile

`password_hash`, `last_login`, `permissions/groups`, `rating`, `clinic_registration_no`,
`photo_url`, `file_binary`, `digital_signature`, `tax_amount`, `cheque_date`,
`audit_log.*`, `notification_settings.*`
