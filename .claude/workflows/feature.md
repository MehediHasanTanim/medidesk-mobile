---
name: feature
description: Full feature development pipeline for MediDesk-Mobile. Orchestrates the complete plan → build → review → test → ship sequence. Run this at the start of any new feature, screen, or significant change.
---

# Workflow: Feature Development Pipeline

This is the master workflow. It sequences the five stage workflows in order and enforces gates between each stage. No stage may begin until the previous stage exits cleanly.

## Trigger

Run this workflow when:
- Starting a new screen or user-facing feature
- Adding a significant new API integration
- Refactoring a module that touches more than two files

Do NOT run for: hotfixes (use `hotfix.md`), documentation-only changes, dependency bumps.

---

## Stage Sequence

```
[1. PLAN] → gate → [2. BUILD] → gate → [3. REVIEW] → gate → [4. TEST] → gate → [5. SHIP]
```

Each stage is defined in its own file. This document defines the gates between them.

---

## Gate Definitions

### Gate 1 — Plan → Build
**Blocked until:**
- [ ] Architect agent has produced a written plan (data model, component breakdown, API surface)
- [ ] All OPEN QUESTIONS in the plan are resolved or explicitly deferred with a decision logged
- [ ] PHI touch-points are identified and flagged (if none, explicitly stated)
- [ ] File paths for all new/modified files are listed

**Output required:** `plan-output.md` saved to `.claude/scratch/` (temp, not committed)

### Gate 2 — Build → Review
**Blocked until:**
- [ ] All files listed in the plan are created or modified
- [ ] TypeScript compiler reports zero errors (`npx tsc --noEmit`)
- [ ] No `console.log` or debug artifacts left in changed files
- [ ] No hardcoded credentials, API keys, or patient data

**Output required:** Coder agent summary listing every file touched

### Gate 3 — Review → Test
**Blocked until:**
- [ ] Reviewer agent verdict is **APPROVED** or **APPROVED WITH NOTES**
- [ ] All BLOCKER and HIGH severity issues are resolved
- [ ] MEDIUM issues are either fixed or logged as known debt with a rationale

**Output required:** Reviewer verdict line + list of deferred items (if any)

### Gate 4 — Test → Ship
**Blocked until:**
- [ ] All test cases in `test.md` have a PASS or SKIP (with reason)
- [ ] No SKIP on any golden-path test case
- [ ] Accessibility smoke test passed on both iOS and Android simulators
- [ ] No regression in previously passing flows

**Output required:** Test summary checklist with PASS/FAIL/SKIP per case

---

## Escalation

If a gate cannot be cleared:
1. Log the blocking issue with specifics
2. Return to the appropriate prior stage (not all the way to Plan unless the design is wrong)
3. Do not ship partial work — leave the branch open and note what remains

---

## Quick Reference

| Stage | Agent | Input | Output |
|-------|-------|-------|--------|
| Plan  | architect | Feature brief | Design doc |
| Build | coder | Design doc | Working code |
| Review | reviewer | Changed files | Verdict + issue list |
| Test  | (manual + automated) | Running app | Test report |
| Ship  | (CI + manual) | Passing tests | Merged PR |
