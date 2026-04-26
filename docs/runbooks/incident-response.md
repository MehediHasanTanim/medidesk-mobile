# Runbook: Incident Response

→ [Back to runbooks](README.md)

For production crashes, data loss, or security vulnerabilities. Time-boxed: diagnose + fix within 2 hours or escalate.

---

## Severity Classification

| Severity | Examples | Target response |
|----------|---------|----------------|
| P0 — Critical | App crashes on launch, data loss, exploitable security issue | Fix and ship within 2 hours |
| P1 — High | Core flow broken (login, patient record, appointment booking) | Fix and ship within 4 hours |
| P2 — Medium | Non-critical feature broken, workaround exists | Normal feature workflow |

Use this runbook for **P0 and P1 only**. P2 issues go through the normal feature workflow.

---

## Step 1 — Diagnose (15 min max)

Write down before touching any code:

```
Bug:               <exact error or behavior>
Reproduction:      <numbered steps>
First seen:        <version / build number if known>
Root cause guess:  <hypothesis>
Files suspected:   <list>
```

```bash
# Find when it was introduced
git log --oneline -20
```

**Do not start fixing until you can reliably reproduce the issue.**

---

## Step 2 — Fix (45 min max)

```bash
git checkout -b hotfix/<short-description>
```

Keep the fix **minimal and surgical**:
- Change only what is necessary — no refactoring, no cleanup alongside the fix
- If the fix requires touching more than 3 files, stop: this is probably not a hotfix

After writing the fix:

```bash
cd medidesk
flutter analyze          # must be clean
flutter test             # relevant tests must pass
```

Add a regression test that fails on the unfixed code and passes after.

---

## Step 3 — Review

Pass the diff to the reviewer agent with this framing:

```
This is a hotfix. The change is intentionally minimal.
Review only the changed lines:
1. Does the fix address the root cause?
2. Could the fix introduce a new failure?
3. Are there security implications?

Do not flag unrelated issues.

Diff:
<paste git diff>
```

Reviewer must return a verdict. Do not ship a hotfix the reviewer flagged as CHANGES REQUIRED.

---

## Step 4 — Smoke Test (15 min max)

- [ ] Original bug can no longer be reproduced
- [ ] Regression test passes
- [ ] Login flow works end-to-end
- [ ] Patient list loads and a patient record opens
- [ ] App builds on both platforms without errors

Full test matrix runs post-merge, not as a blocker.

---

## Step 5 — Ship

```bash
git add <specific files>
git commit -m "hotfix: <description>"
```

PR title: `hotfix: <description>` — the `hotfix:` prefix distinguishes it in the changelog.

Hotfixes may merge during a freeze window by definition.

```bash
# If a release branch is active, backport immediately after merging to main
git checkout release/<version>
git cherry-pick <hotfix-commit-sha>
git push origin release/<version>
```

---

## Step 6 — Post-Incident (within 24 hours)

Write a brief incident summary:

```
## Incident — <date> — <title>

Severity: P0 / P1
Duration: <time from first report to fix live>
Impact: <who was affected, what they couldn't do>

Root cause: <one paragraph>
Fix: <what changed>
Prevention: <how to avoid this class of bug in future>

Follow-up tickets:
- [ ] <any cleanup deferred by the hotfix>
- [ ] <full test run that was skipped>
```

Save to `.claude/scratch/incident-<date>-<title>.md` or log in your issue tracker.

---

## Rollback (if the fix makes things worse)

```bash
# Revert the merge commit on main
git revert <merge-commit-sha>
git push origin main
```

Do not force-push to `main`. A revert commit is safer and auditable.

---

## See Also

- [Release Runbook](release.md) — building and submitting the fix
- `.claude/workflows/hotfix.md` — agent-orchestrated hotfix workflow
