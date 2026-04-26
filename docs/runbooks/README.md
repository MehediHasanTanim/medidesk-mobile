# Runbooks

Step-by-step procedures for common development and operational tasks.

→ [Back to docs](../README.md)

---

## Index

| Runbook | When to use |
|---------|-------------|
| [New Feature](new-feature.md) | Implementing any new screen or offline-first entity |
| [Code Generation](codegen.md) | After changing tables, DAOs, models, or providers |
| [Release](release.md) | Building a release binary for App Store or Play Store |
| [Incident Response](incident-response.md) | Production crash, data loss, or security issue |

---

## Choosing the Right Runbook

```
Production crash / data loss / security issue?
  YES → incident-response.md

Schema or model change?
  → codegen.md (run this before any other work)

New feature or screen?
  → new-feature.md

Submitting a build?
  → release.md
```
