---
name: stf-implement
description: Execute ready work from bd end to end. Use when the user wants to implement, build, code, work on, or knock out an issue or the next ready item. Claims the issue, optionally uses a git worktree for isolation, builds to senior standards, verifies, and closes.
---

# Implement

Take a unit of ready work from claim to verified close. Follows `/stf-plan`; precedes `/stf-wrap`.

> **Assumes bd is initialized here.** If the repo has no `.beads/`, don't run bd commands blindly — tell the user and offer `bd init` (or proceed untracked if they prefer). bd is the source of truth for this workflow.

## Steps

1. **Pick work**: `bd ready` and choose the top item, or use the ID the user gave. `bd show <id>` to load full context — description, acceptance criteria, and any `/stf-research` notes.
2. **Claim atomically**: `bd update <id> --claim` (sets `in_progress` + assignee). Do this *before* writing code.
3. **Isolate if needed**: for parallel or risky work, use a **git worktree** so the main tree stays clean. Single-track changes can stay in place.
4. **Build to senior standards** (per CLAUDE.md):
   - Simplest change that fixes the **root cause** — no temporary patches.
   - Minimal blast radius; touch only what's necessary.
   - Match surrounding code's style and idioms.
5. **Verify BEFORE closing** — this is non-negotiable:
   - Run tests / linters / build.
   - Diff behavior vs. `main` when relevant.
   - Never close on unverified work.
6. **Close**: `bd close <id> --suggest-next` to reveal newly unblocked work. `bd remember "<lesson>"` for any non-obvious thing learned.

## Output

Report what shipped with **verification evidence** (test output, diff). Then offer the next ready item, or `/stf-wrap` if the session is ending.
