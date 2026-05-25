---
name: research
description: Investigate a topic or bd issue in depth and record findings back into bd. Use when the user wants to research, investigate, dig into, evaluate, or gather context on something before deciding or building. Fans out parallel subagents and writes findings to bd notes/design and bd remember.
---

# Research

Investigate deeply, then **persist what you learn into bd** so it survives the session. Typically follows `/brainstorm` and feeds `/plan`.

> **Assumes bd is initialized here.** If the repo has no `.beads/`, don't run bd commands blindly — tell the user and offer `bd init` (or proceed untracked if they prefer). bd is the source of truth for this workflow.

## Steps

1. **Scope it**: a topic or a bd issue ID. If an issue, run `bd show <id>` first to load existing context and acceptance criteria.
2. **Fan out parallel subagents** — one facet per subagent, run concurrently:
   - **Codebase** — `Explore` agent for how things work / where things live
   - **External** — `WebSearch` / `WebFetch` for docs, libraries, prior art
   - **Repo internals** — DeepWiki (`ask_question` / `read_wiki_contents`) for understanding a dependency or OSS repo
3. **Synthesize**: reconcile conflicting findings, separate facts from assumptions, list open questions.
4. **Persist into bd (mandatory):**
   - Attach findings to the issue: `bd note <id> "..."` or `bd update <id> --notes="..." --design="..."`
   - `bd remember "<durable fact>"` for decisions, gotchas, and reference links that future sessions will need.

## Output

A focused findings summary, the **issue IDs you updated**, and remaining open questions. Suggest `/plan` to turn findings into structured work, or `/implement` if the path is now obvious.
