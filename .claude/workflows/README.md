# MediDesk-Mobile Workflows

Automation layer for the MediDesk-Mobile development lifecycle. Each file defines a stage or complete pipeline with explicit inputs, outputs, checklists, and gate conditions.

## Workflows

| File | Purpose | When to Use |
|------|---------|-------------|
| `feature.md` | Master pipeline orchestrator | Start of any new feature or significant change |
| `plan.md` | Stage 1 — System design | Invokes the architect agent |
| `build.md` | Stage 2 — Implementation | Invokes the coder agent |
| `review.md` | Stage 3 — Code review | Invokes the reviewer agent |
| `test.md` | Stage 4 — QA and validation | Manual + automated testing |
| `ship.md` | Stage 5 — Merge and deploy | PR creation, CI, post-merge check |
| `hotfix.md` | Expedited pipeline | Production crashes, data loss, security issues |

## Pipeline Overview

```
feature.md orchestrates:

  plan.md ──Gate 1──► build.md ──Gate 2──► review.md ──Gate 3──► test.md ──Gate 4──► ship.md
```

Each gate is a checklist. A stage may not begin until the prior gate is fully cleared. If a gate fails, return to the previous stage — not to the beginning.

## Agents Used

These workflows coordinate with the agents in `.claude/agents/`:

- `architect` → used in the plan stage
- `coder` → used in the build stage
- `reviewer` → used in the review stage
- `optimizer` → used optionally post-ship for performance passes

## Scratch Files

Stages produce intermediate files saved to `.claude/scratch/`:

```
.claude/scratch/
├── plan-[feature].md
├── build-[feature].md
├── review-[feature].md
└── test-[feature].md
```

These are working documents — not committed to git. Clean them up after shipping (`ship.md` includes a cleanup checklist).

## Choosing the Right Workflow

```
Is it a production crash, data loss, or security issue?
  YES → hotfix.md
  NO  → feature.md (full pipeline)
```
