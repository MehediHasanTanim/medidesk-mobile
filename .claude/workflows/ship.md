---
name: ship
description: Shipping stage workflow for MediDesk-Mobile. Covers PR creation, CI verification, merge, and post-merge checks. Final stage in the feature pipeline. Gate 4 must pass before this stage begins.
---

# Stage 5: Ship

**Agent:** none — this stage is human-executed with explicit checkpoints  
**Prerequisite:** Test stage complete, Gate 4 passed  
**Output:** Merged PR, clean main branch, post-merge verification complete

---

## Pre-Ship Checks

Run all of these before opening the PR:

```bash
git status                             # nothing uncommitted
git diff main --stat                   # only expected files changed
npx tsc --noEmit                       # still clean after any last edits
npx jest --passWithNoTests             # still green
git log main..HEAD --oneline           # review your commit history
```

Squash or clean up commits if the history is noisy — one logical commit per meaningful change.

---

## PR Creation

### Title Format
```
[Type]: Short description (≤ 70 chars)
```

Types: `feat`, `fix`, `refactor`, `chore`, `test`, `docs`

Example: `feat: Add appointment cancellation screen`

### PR Body Template

```markdown
## What
[One paragraph: what this PR does and the user-facing outcome]

## Why
[Why this was built — user story, bug report, product requirement]

## Changes
- [file or component]: [what changed and why]
- [file or component]: [what changed and why]

## Test plan
- [ ] iOS simulator: golden path passes
- [ ] Android emulator: golden path passes
- [ ] Edge cases: [list from test report]
- [ ] No regression in [Flow 1], [Flow 2], [Flow 3]

## PHI / Security
[State explicitly: "This PR does not touch PHI" OR describe what PHI is touched and how it is handled]

## Screenshots
[Required for any screen or UI change — iOS and Android side by side]

## Checklist
- [ ] TypeScript: zero errors
- [ ] ESLint: zero warnings
- [ ] Tests: all passing
- [ ] Accessibility: VoiceOver and TalkBack verified
- [ ] Reviewer verdict: APPROVED
```

---

## CI Requirements

All CI checks must pass before merge. Do not merge with failing checks — investigate and fix:

| Check | Required |
|-------|----------|
| TypeScript | PASS |
| ESLint | PASS |
| Jest (unit + integration) | PASS |
| Build (iOS) | PASS |
| Build (Android) | PASS |
| Code coverage delta | ≥ 0% (no regression) |

If a CI check fails on the PR:
1. Read the full error — do not assume it is a fluke
2. Reproduce locally before pushing a fix
3. Never use `--no-verify` or skip hooks to force a pass

---

## Merge Protocol

- **Merge strategy:** Squash merge into `main` (keeps history clean)
- **Branch delete:** Delete feature branch after merge
- **Merge window:** Do not merge during a freeze window (check `.claude/workflows/freeze.md` if it exists)

```bash
# After merge
git checkout main
git pull origin main
git branch -d feature/[feature-name]
```

---

## Post-Merge Verification

Run within 10 minutes of merging:

- [ ] Pull latest `main` and confirm it builds locally
- [ ] Run smoke tests on `main`:
  ```bash
  npx jest --testPathPattern="smoke"
  ```
- [ ] Verify the feature is reachable in a fresh simulator run on `main`
- [ ] Check CI dashboard — `main` branch is green

If anything fails post-merge:
1. Do not push a quick fix without going through Plan → Build → Review
2. If the failure is severe (crash on launch, data loss), consider reverting:
   ```bash
   git revert [merge-commit-sha]
   git push origin main
   ```

---

## Cleanup

After a successful ship:

- [ ] Delete `.claude/scratch/plan-[feature-name].md`
- [ ] Delete `.claude/scratch/build-[feature-name].md`
- [ ] Delete `.claude/scratch/review-[feature-name].md`
- [ ] Delete `.claude/scratch/test-[feature-name].md`
- [ ] Close any related issues in the tracker and link the merged PR
- [ ] Update `CHANGELOG.md` if the project maintains one

---

## Ship Summary Format

```
## Ship Summary — [feature name]

PR: #[number] — [title]
Merged: [date]
Branch: feature/[name] → main

CI: PASS
Post-merge smoke: PASS
Scratch files cleaned: YES

Status: SHIPPED
```
