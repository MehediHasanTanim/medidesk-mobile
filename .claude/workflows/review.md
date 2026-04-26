---
name: review
description: Code review stage workflow for MediDesk-Mobile. Runs the reviewer agent against the build output to surface bugs, security issues, and plan deviations. Third stage in the feature pipeline.
---

# Stage 3: Review

**Agent:** reviewer  
**Prerequisite:** Build stage complete, Gate 2 passed  
**Output:** Severity-ranked issue list + APPROVED / CHANGES REQUIRED verdict

---

## Pre-Review Setup

Gather these before invoking the reviewer agent:

1. **Get the diff**
   ```bash
   git diff main --stat           # file list
   git diff main                  # full diff for the agent
   ```

2. **Load the original plan** from `.claude/scratch/plan-[feature-name].md`

3. **Load the build summary** from `.claude/scratch/build-[feature-name].md`

---

## Reviewer Agent Prompt Template

```
Review the following code changes for MediDesk-Mobile.

Original architectural plan:
[paste plan contents]

Build summary:
[paste build summary]

Changed files (git diff):
[paste full diff]

Review for:
1. Logic bugs and incorrect assumptions
2. TypeScript type safety (no any, proper null handling)
3. Security: unvalidated inputs, insecure storage, exposed secrets
4. PHI handling: patient data stored or logged anywhere it shouldn't be
5. Error handling completeness: network failure, empty response, permission denial
6. Performance: unnecessary re-renders, missing virtualization, heavy synchronous ops
7. Accessibility: all interactive elements labeled, roles set
8. Deviation from the architectural plan

Return a severity-ranked issue list (BLOCKER / HIGH / MEDIUM / LOW) and a final verdict.
```

---

## Issue Resolution Protocol

After the reviewer returns its list:

### BLOCKER issues
- Must be fixed before proceeding — no exceptions
- Return to Build stage for each blocker
- Re-run reviewer after fixes (full review, not spot check)

### HIGH issues
- Must be fixed before proceeding in most cases
- Exception: if HIGH is a known acceptable tradeoff, document the decision with rationale
- Partial re-review acceptable if change is isolated

### MEDIUM issues
- Fix now if quick (< 15 min); otherwise log as tracked debt
- Debt must be logged in the project issue tracker, not just noted here

### LOW issues
- Defer unless trivially fast to fix
- No logging required

---

## Review Checklist (independent of agent)

Run these checks manually — the reviewer agent reads code but cannot run it:

- [ ] App builds without warnings: `npx react-native build-ios` / `build-android`
- [ ] New screens registered in navigator and reachable
- [ ] Deep link or param passing works if the feature involves navigation
- [ ] Any new environment variable added to `.env.example` (not `.env`)
- [ ] No sensitive data in `AsyncStorage` without encryption

---

## Review Summary Format

```
## Review Summary — [feature name]

Reviewer verdict: [APPROVED | APPROVED WITH NOTES | CHANGES REQUIRED]

Blockers resolved: [n/n]
High issues resolved: [n/n]
Medium issues deferred: [list with tracker links]
Low issues deferred: [count]

Ready for: [Test stage | Build stage (re-work required)]
```

Save to `.claude/scratch/review-[feature-name].md`.
