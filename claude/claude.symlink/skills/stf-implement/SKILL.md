---
name: stf-implement
description: Execute ready work from bd end to end. Use when the user wants to implement, build, code, work on, or knock out an issue or the next ready item. Claims the issue, optionally uses a git worktree for isolation, builds to senior standards, verifies, and closes.
---

# Implement

Take a unit of ready work from claim to verified close. Follows `/stf-plan`; precedes `/stf-wrap`.

> **Assumes bd is initialized here.** If the repo has no `.beads/`, don't run bd commands blindly — tell the user and offer `bd init` (or proceed untracked if they prefer). bd is the source of truth for this workflow.

## Core procedure

Read and follow `references/core.md` — it defines the canonical claim→implement→verify→close algorithm, the `stf-checkpoint` pause primitive, and the `bd-loop-fail` escalation path. Both this skill and the headless `stf-implement` subagent share that file as the single source of truth.

## Output

Report what shipped with **verification evidence** (test output, diff). Then offer the next ready item, or `/stf-wrap` if the session is ending.
