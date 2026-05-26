---
name: stf-brainstorm
description: Think through a problem collaboratively until the framing is solid, then capture it as a bd epic. Use when the user wants to brainstorm, explore an idea, "throw ideas around", or kick off new work before planning. Holds a back-and-forth dialogue and creates NOTHING until the user confirms the framing. Does NOT order, prioritize, or plan — that comes later.
---

# Brainstorm

Think through a problem **with** the user until the framing is solid, then capture that framing as a bd epic. **The specification IS the epic.** This is the front of the workflow; it feeds `/stf-research` and `/stf-plan`.

The goal is a shared understanding the user actually agrees with — not a pile of captured ideas. Diverge in conversation; converge before you write anything to bd.

> **Assumes bd is initialized here.** If the repo has no `.beads/`, don't run bd commands blindly — tell the user and offer `bd init` (or proceed untracked if they prefer). bd is the source of truth for this workflow.

## Steps

1. **Explore context first.** Before asking anything, look at the project — relevant files, docs, recent commits — so your questions are informed, not generic. Use Explore subagents for broad sweeps.
2. **Scope check.** If the topic spans several independent subsystems, say so and decompose it first. Brainstorm **one** sub-project at a time; a single epic should map to a single coherent problem.
3. **Clarifying dialogue — one question at a time.** Ask the most important open question, wait for the answer, then ask the next. Prefer multiple-choice questions (they're easier to answer than open prompts). Focus on purpose, constraints, and what success looks like. Do not batch a questionnaire.
4. **Propose 2–3 approaches** with trade-offs, and **lead with your recommendation**. Let the user react and steer.
5. **Present the framing in sections**, scaled to the topic's complexity (problem statement, scope/non-goals, chosen approach, surviving ideas). **Confirm after each section** before moving on — adjust based on what you hear.
6. **APPROVAL GATE — do NOT create anything in bd until the user confirms the framing.** No `bd create`, no children, no `bd remember` of the spec until they've signed off on the design. This skill's whole point is that creation comes *after* agreement.

## Capture (only after the approval gate)

Once the user confirms, write the agreed framing into bd:

- **Create exactly one epic — it is the specification:**
  ```
  bd create --title="..." --type=epic \
    --description="<problem statement + scope/non-goals>" \
    --design="<chosen approach + rationale, including approaches considered>"
  ```
- **Children = only the idea titles that SURVIVED the dialogue.** Keep them lightweight: terse titles parented to the epic via `--type=task --deps "parent-child:<epic-id>"`. The parent link is structural — it's what lets `/stf-plan` find them via `bd children <epic>`. Leave priority to bd's default; setting it is `/stf-plan`'s job. This is **not** a dump — discarded ideas stay discarded.
- `bd remember "<insight>"` for any cross-cutting realization worth keeping across sessions.
- Self-review the epic with `bd create --validate` / `bd lint` — catch placeholders, contradictions, ambiguity, or scope creep before handing off. **Expected:** lint will warn `Missing: ## Success Criteria` — that's by design here; success/acceptance criteria belong to `/stf-plan`. Do **not** silence it by adding criteria to the epic.

## Boundary with /stf-plan (keep these distinct)

| brainstorm → epic | plan → work graph |
| --- | --- |
| problem statement, scope, chosen approach + rationale | — |
| lightweight surviving child **titles** | acceptance criteria, priorities |
| — | dependencies, ordering |

Brainstorm gives the epic and bare child titles. It does **not** add acceptance criteria, dependencies, or priorities — that's `/stf-plan`. It does not evaluate feasibility deeply — that's `/stf-research`.

## Output

Report the **epic ID** and the surviving **child idea IDs**. Then hand off: `/stf-plan <epic-id>` to structure it into ordered work, or `/stf-research <id>` to dig into a promising idea first.
