---
name: hotfix
description: Expedited workflow for production-critical bugs in MediDesk-Mobile. Skips architect agent and reduces planning overhead. Use only for crashes, data loss, or security issues — not for "urgent" features.
---

# Workflow: Hotfix

An accelerated path for production-critical issues. Planning is still required, but it is lightweight and immediate. The reviewer and test stages are mandatory — they cannot be skipped even under time pressure.

## When to Use This Workflow

**Use hotfix when:**
- App crashes on launch or during a critical flow (booking, login, patient record access)
- Data is being lost or corrupted
- A security vulnerability is actively exploitable
- A CI/CD pipeline failure is blocking all other work

**Do not use hotfix for:**
- Features that are "urgent"
- Non-critical bugs that have a workaround
- Performance issues that don't cause failures

---

## Hotfix Sequence

```
[DIAGNOSE] → [FIX] → [REVIEW] → [SMOKE TEST] → [SHIP]
```

Target: diagnosing and shipping a hotfix within 2 hours. If a fix takes longer, it is not a hotfix — use the full feature workflow.

---

## Stage 1: Diagnose (15 min max)

Write down:

```
Bug: [exact error message or behavior]
Reproduction steps: [numbered list]
First failing version: [commit sha or build number if known]
Root cause hypothesis: [your best guess before diving in]
Files suspected: [list]
```

Run:
```bash
git log --oneline -20         # find when it was introduced
git bisect start              # if cause is unclear
```

**Do not start fixing until you can reliably reproduce the bug.**

---

## Stage 2: Fix (45 min max)

Keep the fix minimal and surgical:

- Change only what is necessary to fix the bug — no refactoring, no cleanup
- If fixing the bug requires touching more than 3 files, stop and assess: this might not be a hotfix
- Add a regression test that fails before the fix and passes after

```bash
git checkout -b hotfix/[short-description]
```

After writing the fix:

```bash
npx tsc --noEmit               # must be clean
npx jest --testPathPattern="[affected area]" --verbose
```

---

## Stage 3: Review (20 min max)

Pass the fix to the reviewer agent with this context:

```
This is a hotfix. The change is intentionally minimal.
Review only the changed lines for:
1. Does the fix actually address the root cause?
2. Could the fix introduce a new failure?
3. Are there any security implications?

Do not flag unrelated issues — log them separately for the normal workflow.

Diff:
[paste git diff]
```

Reviewer must return a verdict. CHANGES REQUIRED on a hotfix means fix the issue and re-review — do not ship a hotfix the reviewer flagged.

---

## Stage 4: Smoke Test (15 min max)

Focused — not the full test matrix:

- [ ] Bug can no longer be reproduced
- [ ] Regression test passes
- [ ] The two most critical app flows still work (login, primary feature)
- [ ] App builds on both platforms without error

Full platform test matrix runs post-merge as a follow-up, not a blocker.

---

## Stage 5: Ship

Same as the main ship workflow with two differences:

1. **PR title prefix:** `hotfix:` instead of `feat:` or `fix:`
2. **No freeze exception needed** — hotfixes may merge during a freeze window by definition

```bash
# After merge to main, also backport to the release branch if one is active
git checkout release/[version]
git cherry-pick [hotfix-commit-sha]
git push origin release/[version]
```

Post-merge: same smoke test as the main ship workflow.

---

## Post-Hotfix Follow-up

Within 24 hours of shipping:
- [ ] Write a brief incident summary: root cause, timeline, fix, prevention
- [ ] Create a follow-up ticket for any related cleanup the hotfix deferred
- [ ] Run the full test matrix that was skipped during the hotfix
