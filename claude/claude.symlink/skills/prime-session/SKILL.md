---
name: prime-session
description: Start a work session with full context from bd. Use at the start of a session, after /clear or compaction, or when the user asks to "prime", "get up to speed", "what's the status", or "what should I work on next". Loads ready work, in-progress items, blockers, and relevant memories into a briefing.
---

# Prime Session

Load the full state of the work into context and produce a short situational briefing. This is the entry point of the workflow — it precedes `/brainstorm`, `/plan`, and `/implement`.

> **Assumes bd is initialized here.** If the repo has no `.beads/`, don't run bd commands blindly — tell the user and offer `bd init` (or proceed untracked if they prefer). bd is the source of truth for this workflow.

## Steps

1. **Reload bd context**: run `bd prime` (gives commands + session rules).
2. **Survey the board**:
   - `bd ready` — what can be worked now (no blockers)
   - `bd list --status=in_progress` — what's already claimed/active
   - `bd blocked` — what's stuck and why
   - `bd stale` — issues with no recent activity that may need attention
3. **Recall relevant memory**: if the user named a focus area, run `bd memories <keyword>` to surface durable insights and decisions.

## Output

A tight briefing, not a dump:

- **In flight** — in-progress issues (IDs + one line each)
- **Ready** — top 2–3 picks from `bd ready` with why they're good next steps
- **Blocked / stale** — anything needing a decision
- **Suggested next** — usually `/implement <id>` (clear path), `/plan` (work needs structuring), or `/research <id>` (needs investigation)

Keep it scannable. The goal is for the user to know exactly where things stand and what to do next in under ten seconds.
