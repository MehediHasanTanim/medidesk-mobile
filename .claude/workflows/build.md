---
name: build
description: Implementation stage workflow for MediDesk-Mobile. Runs the coder agent against the architect's plan to produce working TypeScript/React Native code. Second stage in the feature pipeline.
---

# Stage 2: Build

**Agent:** coder  
**Prerequisite:** Completed plan from Stage 1 (Gate 1 passed)  
**Output:** All files from the plan created/modified, TypeScript clean, no debug artifacts

---

## Pre-Build Setup

Before invoking the coder agent:

1. **Create a feature branch**
   ```bash
   git checkout -b feature/[feature-name]
   ```

2. **Confirm the environment is clean**
   ```bash
   npx tsc --noEmit        # zero errors before you add any
   npx eslint src/          # zero new errors baseline
   ```

3. **Read the plan** — pass the full contents of `.claude/scratch/plan-[feature-name].md` to the coder agent

---

## Coder Agent Prompt Template

```
Implement the following feature for MediDesk-Mobile per this architectural plan:

[paste full plan contents here]

Implementation requirements:
- TypeScript strict mode, no `any`
- React Native functional components with StyleSheet.create
- Follow existing file structure and import aliases
- Handle loading, error, and empty states in every screen
- Add accessibilityLabel and accessibilityRole to all interactive elements
- No console.log, no TODO comments, no placeholder data

Produce complete file contents for each file in the plan's file list.
```

---

## Build Checklist

Work through the plan's file list top-to-bottom. After each file:

- [ ] File created at the exact path specified in the plan
- [ ] All props match the types defined in the data model
- [ ] Component handles: loading state, error state, empty/null data
- [ ] No hardcoded strings that should be constants or i18n keys
- [ ] No inline styles — all via `StyleSheet.create`
- [ ] Imports use project aliases, not relative `../../` paths
- [ ] No unused imports

After all files are done:

- [ ] `npx tsc --noEmit` — zero errors
- [ ] `npx eslint src/ --max-warnings 0` — zero new warnings
- [ ] `git diff --stat` — only files from the plan's file list appear (no accidental changes)
- [ ] `grep -r "console.log" src/` — no log statements in changed files
- [ ] `grep -r "TODO\|FIXME\|HACK" src/` — no new markers introduced

---

## Iterating Within Build

If the coder hits an ambiguity in the plan:

1. **Minor gap** (a missing field, unclear prop type): make the conservative choice and log it in the build summary
2. **Design conflict** (plan says X but the existing code requires Y): stop, return to architect for clarification — do not guess on structural decisions
3. **Blocked by missing API**: stub the API call with a clearly named placeholder function and flag it in the build summary

---

## Build Summary Format

When the coder agent finishes, it must produce:

```
## Build Summary — [feature name]

Files created:
- src/screens/[Name]Screen.tsx
- src/components/[Name].tsx

Files modified:
- src/navigation/AppNavigator.tsx (added route)
- src/store/[slice].ts (added actions)

Type check: PASS
Lint: PASS

Deferred items:
- [anything not implemented, with reason]

Ready for: Review stage
```

Save this to `.claude/scratch/build-[feature-name].md`.
