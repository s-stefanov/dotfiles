---
name: brainstorm
description: Diverge on a problem or idea and capture every angle into bd. Use when the user wants to brainstorm, explore options, "throw ideas around", or kick off new work before any planning. Creates a bd epic and lightweight child issues. Does NOT order, prioritize, or plan — that comes later.
---

# Brainstorm

Diverge widely on a topic and capture **everything** into bd so no idea is lost. This is the front of the workflow; it feeds `/research` and `/plan`.

> **Assumes bd is initialized here.** If the repo has no `.beads/`, don't run bd commands blindly — tell the user and offer `bd init` (or proceed untracked if they prefer). bd is the source of truth for this workflow.

## Steps

1. **Frame the topic** in one line. Confirm it with the user if ambiguous.
2. **Diverge** — generate many distinct ideas, angles, and approaches. Favor breadth over judgment; do not filter yet.
   - For broad topics, **fan out parallel subagents** (Explore / general-purpose), each taking a different angle, then merge their output. One angle per subagent.
3. **Capture into bd (mandatory — no markdown TODO lists):**
   - Create one **epic** for the topic: `bd create --title="..." --type=epic`
   - Capture each idea as a child issue **parented to the epic**: `bd create --title="..." --type=task --priority=3 --deps "parent-child:<epic-id>"`. The parent link is what lets `/plan` later find these via `bd children <epic>` — without it the idea is orphaned. (`bd q` is faster but only takes `--type/--priority/--labels`, *not* `--deps`, so only reach for it if you immediately link with `bd dep add`.) Keep ideas lightweight: terse titles, low/backlog priority.
   - `bd remember "<insight>"` for any cross-cutting realization worth keeping across sessions.

## Do NOT

- Prioritize, sequence, or add dependencies — that's `/plan`.
- Evaluate feasibility deeply — that's `/research`.
- Discard ideas. Capture first, judge later.

## Output

Report the **epic ID** and the list of captured **idea IDs**. Then suggest the next step: `/research <id>` to dig into a promising idea, or `/plan <epic>` to structure them into work.
