# API Contract

→ [Back to docs](../README.md)

Base URL: `AppConfig.current.baseUrl` (e.g. `https://api.medidesk.app/api/v1`)  
All paths below are relative to that base. Defined in `core/network/api_endpoints.dart`.

---

## Authentication

| Method | Path | Request | Response |
|--------|------|---------|---------|
| POST | `/auth/token/` | `{username, password}` | `{access, refresh, user: {id, role, ...}}` |
| POST | `/auth/token/refresh/` | `{refresh}` | `{access}` |
| POST | `/auth/logout/` | `{refresh}` | 204 |
| GET  | `/auth/me/` | — | `UserRow` object |

JWT access token lifetime: configured on the server. The `AuthInterceptor` in `core/network/interceptors/auth_interceptor.dart` handles automatic token refresh on 401.

---

## Lookup Endpoints (read-only)

Full-list responses, no `updated_after`. Refreshed by `LookupSyncHandler`.

| Path | Response shape | Notes |
|------|---------------|-------|
| `/chambers/` | `[...]` | Small set, no pagination |
| `/users/` | `[...]` | Active staff |
| `/specialities/` | `[...]` | Flat list |
| `/doctor-profiles/` | `[...]` | Flat list |
| `/medicines/generic/?page=N&limit=500` | `{results, next, count}` | Paginated |
| `/medicines/brand/?page=N&limit=500` | `{results, next, count}` | Paginated |

---

## Mutable Resource Endpoints

### Delta pull (GET)

All mutable entities support delta pulls:

```
GET /<entity>/?updated_after=<ISO8601 UTC>&limit=500
→ { results: [...], next: "<url|null>", count: N }
```

Deleted records are included in the response with `"is_deleted": true`.

**Entities:** `/patients/`, `/appointments/`, `/consultations/`, `/prescriptions/`, `/prescription-items/`, `/test-orders/`, `/invoices/`, `/invoice-items/`, `/payments/`

### Mutations (POST / PATCH / DELETE)

| Operation | Method | Path | Notes |
|-----------|--------|------|-------|
| Create | POST | `/<entity>/` | Body must include `"local_id": "<uuid>"` |
| Update | PATCH | `/<entity>/<server_id>/` | Partial update |
| Delete | DELETE | `/<entity>/<server_id>/` | Server sets `is_deleted=true` (soft-delete) |

---

## Sync Correlation (`local_id`)

Every POST body sent by the app includes `"local_id": "<device UUID>"`.

The server **must** echo `local_id` in the 201 response body. The app uses this to match the response back to the local Drift record and store the assigned `server_id`.

```json
// POST /patients/
{ "local_id": "f47ac10b-...", "full_name": "Rahim Uddin", ... }

// 201 response
{ "id": 42, "local_id": "f47ac10b-...", "full_name": "Rahim Uddin", ... }
```

---

## File Upload

```
POST /report-documents/
Content-Type: multipart/form-data

Fields:
  file          binary
  patient_id    UUID (local_id of patient)
  category      blood_test | imaging | biopsy | other
  test_order_id UUID (optional)
  notes         string (optional)

Response 201:
  { id, patient_id, category, file_url, created_at, ... }
```

Files are queued by `FileUploadQueue` and uploaded by `BackgroundSyncTask`. Display uses `file_url` — binary is never cached locally.

---

## Error Shape

Django REST Framework standard error format:

```json
{ "detail": "Not found." }
{ "field_name": ["This field is required."] }
```

Handled by `core/network/interceptors/error_interceptor.dart` → converted to `AppException`.

---

## See Also

- [Sync System](sync-system.md) — how API calls fit into the push/pull flow
- [ADR-001](../decisions/ADR-001-drift-local-db.md) — why local-first over API-first
