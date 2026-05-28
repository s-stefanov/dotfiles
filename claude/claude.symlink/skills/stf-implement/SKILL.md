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

## Stuck mid-task? Pause cleanly via `stf-checkpoint`

If you hit a decision or missing-info gap you can't resolve on your own, **do not guess and do not silently stall**. Pause via the checkpoint primitive:

```bash
Q_ID=$(stf-checkpoint <work-id> "<question>" [--options "a,b,c"])
exit_code=$?
```

`stf-checkpoint` **always dual-writes first** (creates a human-labeled question-bead as a blocker, drops a back-reference comment on the work-bead). The work-bead drops out of `bd ready` until the question is answered.

Then bifurcate on the exit code:

### Exit 0 — attended (user present)

Present the question interactively:

```
AskUserQuestion(...)   # Claude tool — present the question to the user
```

After the user answers, **close the Q-bead** to record the answer and unblock the work-bead:

```bash
bd comment "$Q_ID" "<answer>" && bd close "$Q_ID" --reason "Responded"
# (or: bd human respond "$Q_ID" -r "<answer>" — once the upstream bug is fixed)
```

Then continue the same session with the answer in hand.

### Exit 3 — unattended (background / ScheduleWakeup-driven)

The dual-write is already done. Terminate this loop pass cleanly:

```
exit with reason: "human gate (bead $Q_ID)"
```

The next loop pass will skip the work-bead (it's blocked). A human resumes with:

```bash
bd human respond "$Q_ID" -r "<answer>"
# (workaround: bd comment "$Q_ID" "<answer>" && bd close "$Q_ID" --reason "Responded")
```

### Attended detection

`stf-checkpoint` reads `STF_LOOP_ATTENDED` (set by `/stf-loop` based on invocation mode).  
- Unset (direct `/stf-implement` invocation) → defaults to attended (exit 0).  
- `/stf-loop` must set `STF_LOOP_ATTENDED=0` for ScheduleWakeup passes.

Read `references/bd-human-pause-primitive.md` (in this skill's folder) for the full design, the back-pressure semantics, and the upstream-bug workaround.

## Failure in loop context? Record and escalate via `bd-loop-fail`

When `/stf-implement` is called from `/stf-loop` (not attended) and fails, the loop must not spin on the same bead indefinitely. Use:

```bash
bd-loop-fail <work-id> "<one-line failure summary>" [--max N]
```

- **Exit 0**: attempt recorded (count < MAX), loop should retry the bead next pass.
- **Exit 1**: escalated — MAX reached, human-labeled blocker bead created, work-bead reset to open. Loop moves on; `bd ready --exclude-label human` will skip it.

Default MAX is 2. Override with `--max N` from the loop's state file or arg.

Read `references/bd-human-pause-primitive.md` for the failure escalation section and the full design.

## Output

Report what shipped with **verification evidence** (test output, diff). Then offer the next ready item, or `/stf-wrap` if the session is ending.
