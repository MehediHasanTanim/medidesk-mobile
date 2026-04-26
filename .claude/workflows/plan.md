---
name: plan
description: Planning stage workflow for MediDesk-Mobile. Runs the architect agent against a feature brief and produces a structured design document. First stage in the feature pipeline.
---

# Stage 1: Plan

**Agent:** architect  
**Prerequisite:** Feature brief from product/user (what, why, acceptance criteria)  
**Output:** Structured design document ready for the coder agent

---

## Inputs Required Before Starting

Collect these before invoking the architect agent:

```
Feature name:
User story / acceptance criteria:
Screens affected:
APIs involved (known or suspected):
Deadline or priority:
Any known constraints (design system, existing patterns to follow):
```

If any input is missing, ask before proceeding. A plan built on assumptions produces a build that misses the target.

---

## Architect Agent Prompt Template

```
Feature: [name]

User story: [as a ... I want ... so that ...]

Acceptance criteria:
- [criterion 1]
- [criterion 2]

Screens/flows affected: [list]

Known API endpoints: [list or "TBD"]

Constraints: [design system components, existing patterns, performance requirements]

Produce a full architectural plan including:
- Data model with TypeScript interfaces
- Component/screen breakdown with props contracts
- State management strategy
- API surface (request/response shapes, error cases)
- File paths for all new and modified files
- Open questions that need resolution before build starts
```

---

## Plan Checklist

The architect output must cover all of these before Gate 1 passes:

- [ ] **Data model** — all entities with typed fields, no `any`
- [ ] **Component list** — every new component named with its parent screen
- [ ] **Props contracts** — input/output types for each component
- [ ] **State strategy** — what lives in Zustand, Context, or local `useState`
- [ ] **API surface** — at minimum: method, path, request shape, success shape, error cases
- [ ] **Navigation changes** — any new routes or param changes in the navigator
- [ ] **PHI declaration** — explicitly states whether the feature touches patient data
- [ ] **File list** — complete list of files to create or modify (paths only, no code)
- [ ] **Open questions** — unresolved decisions flagged for human input

---

## Common Plan Failure Modes

These patterns mean the plan is incomplete — do not proceed to Build:

- Data model uses `any`, `object`, or untyped arrays
- API surface says "TBD" without a resolution path
- State strategy is missing or vague ("we'll figure it out")
- Open questions include decisions about core behavior (not just styling)
- PHI declaration is absent when the feature touches appointments, notes, or patient records

---

## Saving the Plan

Save the architect output to `.claude/scratch/plan-[feature-name].md` before moving to Build.  
This file is temporary — do not commit it. It exists only to pass context to the coder agent.
