---
name: recall
description: Pull relevant past context back into the conversation from bd. Use when the user asks "what do we know about X", "did we decide…", "have we looked at this", or needs to recover context mid-task. Searches bd memories, issues, and shows detail — returns a tight synthesis, not a dump.
---

# Recall

Random-access lookup into the project's memory. Usable at any point in the workflow when context is missing.

> **Assumes bd is initialized here.** If the repo has no `.beads/`, say so plainly — there's nothing to recall — and offer `/research` instead.

## Steps

1. **Durable insights**: `bd memories <keyword>` — decisions, gotchas, and facts saved via `bd remember`.
2. **Related issues**: `bd search <query>` to find relevant issues; `bd show <id>` for detail on the promising ones.
3. **Synthesize**: produce a **tight, relevant summary** — surface decisions made, gotchas, and related issue IDs. Do not paste raw output.

## If nothing is found

Say so plainly and suggest `/research <topic>` to investigate and capture it for next time.
