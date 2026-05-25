---
name: plan
description: Turn ideas or research into a structured, ordered bd work graph. Use when the user wants to plan, break down, structure, scope, or sequence work — typically after /brainstorm or /research. Creates and refines epic + child issues with acceptance criteria, priorities, and dependencies so `bd ready` surfaces work in the right order.
---

# Plan

Convert loose ideas and research into a **dependency-aware backlog** that `bd ready` can drive. Follows `/brainstorm` and `/research`; feeds `/implement`.

> **Assumes bd is initialized here.** If the repo has no `.beads/`, don't run bd commands blindly — tell the user and offer `bd init` (or proceed untracked if they prefer). bd is the source of truth for this workflow.

## Steps

1. **Gather inputs**: an epic, topic, or set of idea issues. `bd show <epic>` / `bd children <epic>` to see what exists.
2. **Make each unit of work a well-formed bd issue** (mandatory):
   - Clear description (**why** it exists + **what** done looks like)
   - `--acceptance="..."` — concrete acceptance criteria
   - `--design="..."` — key decisions, where relevant (pull from `/research` notes)
   - Correct `--type` (feature/task/bug) and `--priority` (0–4)
3. **Sequence with dependencies**: `bd dep add <issue> <depends-on>` so prerequisite work blocks dependent work. This is what makes `bd ready` meaningful.
4. **Validate**: `bd lint` (or create with `--validate`) to catch missing sections; `bd ready` to confirm the entry points are the ones you expect.
5. **Prune**: keep only issues that represent real work. `bd supersede` or `bd close` ideas that don't make the cut, with a reason.

## Output

Show the resulting graph — `bd ready` (entry points) and `bd blocked` (what's waiting) — and suggest `/implement` to start the top ready item.
