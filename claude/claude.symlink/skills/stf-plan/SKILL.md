---
name: stf-plan
description: Turn ideas or research into a structured, ordered bd work graph. Use when the user wants to plan, break down, structure, scope, or sequence work — typically after /stf-brainstorm or /stf-research. Creates and refines epic + child issues with acceptance criteria, priorities, and dependencies so `bd ready` surfaces work in the right order.
---

# Plan

Convert loose ideas and research into a **dependency-aware backlog** that `bd ready` can drive. Follows `/stf-brainstorm` and `/stf-research`; feeds `/stf-implement`.

> **Handoff from `/stf-brainstorm`:** it hands you an epic (problem + chosen approach + rationale) and lightweight surviving child **titles** — nothing more. **You** own everything that orders the work: acceptance criteria, priorities, dependencies, and sequencing. Don't restate the epic's problem/approach; build the work graph on top of it.

> **Assumes bd is initialized here.** If the repo has no `.beads/`, don't run bd commands blindly — tell the user and offer `bd init` (or proceed untracked if they prefer). bd is the source of truth for this workflow.

## Steps

1. **Gather inputs**: an epic, topic, or set of idea issues. `bd show <epic>` / `bd children <epic>` to see what exists.
2. **Make each unit of work a well-formed bd issue** (mandatory):
   - Clear description (**why** it exists + **what** done looks like)
   - `--acceptance="..."` — concrete acceptance criteria
   - `--design="..."` — key decisions, where relevant (pull from `/stf-research` notes)
   - Correct `--type` (feature/task/bug) and `--priority` (0–4)
3. **Sequence with dependencies**: `bd dep add <issue> <depends-on>` so prerequisite work blocks dependent work. This is what makes `bd ready` meaningful.
4. **Validate**: `bd lint` (or create with `--validate`) to catch missing sections; `bd ready` to confirm the entry points are the ones you expect.
5. **Prune**: keep only issues that represent real work. `bd supersede` or `bd close` ideas that don't make the cut, with a reason.

## Output

Show the resulting graph — `bd ready` (entry points) and `bd blocked` (what's waiting) — and suggest `/stf-implement` to start the top ready item.
