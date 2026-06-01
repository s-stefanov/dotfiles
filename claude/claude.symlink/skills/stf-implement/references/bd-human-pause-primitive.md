# bd-human as pause primitive

The pause/resume mechanism the autonomous loop (epic
`personal-dev-workflow-zhn`) needs. Built on bd's native `human` label —
nothing about bd itself is forked or extended.

## The shape

```
  /stf-implement (mid-task) ──┐                     ┌── ready picker
       or                     ├──→ bd-ask-human ────┤   excludes human-labeled
  /stf-loop (between passes) ─┘     creates Q-bead  │   blockers hide work
                                    blocks work     │
                                                    ▼
                                          human answers via
                                          `bd human respond`
                                              (closes Q-bead,
                                               work returns to ready)
```

## The two pieces

### 1. Ready-picker filter

`bd ready` already supports `--exclude-label`. The canonical loop incantation:

```bash
bd ready --parent <epic-id> --exclude-label human
```

No bd CLI changes were needed. Any consumer that picks the next ready bead in
the loop **must** pass `--exclude-label human` or human-pending work will spin.

### 2. `bd-ask-human` helper

`bin/bd-ask-human` (symlinked to `~/.local/bin/`). Atomic dual-write:

```bash
bd-ask-human <work-id> "<question>" [--options "a,b,c"] [--priority P0..P4]
```

What it does, in one shell call:

1. Creates a child **question-bead** of `<work-id>`, typed `decision`, labeled
   `human`, with `<work-id>` recorded as depending on it (i.e. the question
   blocks the work).
2. Drops a back-reference **comment** on `<work-id>` pointing at the question.
3. Prints the question-bead ID on stdout; prints a human-readable summary +
   resume command on stderr.

Effect: the work-bead drops out of `bd ready` (blocked); the question-bead
drops out of `bd ready --exclude-label human` (labeled). `bd human list`
surfaces the question.

## Resume

```bash
bd human respond <question-id> -r "<reply>"
```

Adds the reply as a comment and closes the question-bead. The work-bead's
blocker clears; the next `bd ready` pass picks it up.

> **Upstream bug (bd v1.0.4 Homebrew):** `bd human respond` errors with
> `storage is nil`. Until that's fixed, the equivalent manual form works:
> ```bash
> bd comment <question-id> "<reply>"
> bd close <question-id> --reason "Responded"
> ```

## Interactive-when-attended / async-fallback checkpoint (`stf-checkpoint`)

`stf-checkpoint` wraps `bd-ask-human` with attended/unattended bifurcation (issue 8ye). Use it instead of bare `bd-ask-human` in all skill/loop code.

```bash
Q_ID=$(stf-checkpoint <work-id> "<question>" [--options "a,b,c"])
exit_code=$?
# exit 0 = attended; exit 3 = unattended; exit 2 = usage error
```

**Attended detection** — priority order (Claude Code Bash shell state does not persist across tool calls, so env var alone is unreliable):
1. `STF_LOOP_ATTENDED` env var — set explicitly for same-process bash calls
2. `.claude/stf-loop-attended` file — fallback for environments that write it; survives across Bash tool calls
3. Default: `1` (attended) — safe default for direct `/stf-implement` invocations

Note: with the `bd-worker` subagent path, stf-loop no longer writes the attended-flag file. The subagent always takes the unattended (exit 3) path directly.

**Attended path (exit 0):**
1. Dual-write already done.
2. Present question with `AskUserQuestion` (Claude tool).
3. Record answer: `bd comment "$Q_ID" "<answer>" && bd close "$Q_ID" --reason "Responded"`.
4. Continue same session.

**Unattended path (exit 3):**
1. Dual-write already done.
2. Terminate loop pass with reason `"human gate (bead $Q_ID)"`.
3. Human resumes via `bd human respond` (or manual equivalent).

**Install:** `ln -sf "$HOME/dev/personal-dev-workflow/bin/stf-checkpoint" ~/.local/bin/stf-checkpoint`

---

## Why a separate question-bead (and not labeling the work-bead)

`bd human respond` adds a comment **and closes** the bead. If the `human`
label sat on the work-bead, responding would close in-flight work. The
question owns its own bead: closing it closes the question, not the work.

This is a framing correction relative to the original 458 description, which
read "apply the 'human' label" to the work-bead directly. Verified
empirically before implementation; recorded as a `--append-notes` correction
on `personal-dev-workflow-458`.

## Install

The script source lives in the `personal-dev-workflow` repo at `bin/bd-ask-human` (kept in the repo so it's editable alongside other personal tooling and visible in version control). It's installed onto PATH via a symlink:

```bash
ln -sf "$HOME/dev/personal-dev-workflow/bin/bd-ask-human" ~/.local/bin/bd-ask-human
```

(`~/.local/bin/` is already on PATH in this environment.) The skill itself just calls `bd-ask-human` — it doesn't need to know where the script lives.

## When to use it

- **`/stf-implement`, mid-task** — when the agent hits an irrecoverable
  decision or missing-info gap, it asks via `bd-ask-human` and exits cleanly.
  The next session (or `bd human respond`) resumes the bead.
- **`/stf-loop`, between passes** (once 54x lands) — when the loop has no
  ready work but a question is pending, it stops with a
  "waiting on human" message rather than spinning.

---

## Failure escalation: `bd-loop-fail`

A second use of the same primitive, for the retry-then-escalate policy (issue 6qk). When `/stf-loop` routes a failed bead through this script it does:

```bash
bd-loop-fail <work-id> "<one-line failure summary>" [--max N]
```

1. Appends `[loop-attempt N/MAX] <summary>` to the work-bead's notes (parseable on subsequent passes — no new bd field).
2. If `N < MAX` (default 2): exits 0 → loop retries next pass.
3. If `N >= MAX`: resets work-bead status to `open` (un-claims), adds a failure-trail comment on the work-bead, calls `bd-ask-human` to create a human-labeled blocker bead, exits 1 → loop moves on.

The blocker bead is the same shape as a decision question from `bd-ask-human` — when a human dismisses it, the work-bead re-enters `bd ready` on the next pass.

**Install:** `ln -sf "$HOME/dev/personal-dev-workflow/bin/bd-loop-fail" ~/.local/bin/bd-loop-fail`

### Exit codes

| Code | Meaning | Loop action |
|---|---|---|
| 0 | Recorded, under limit | Retry bead next pass |
| 1 | Escalated (MAX reached) | Skip; bead now blocked |
| 2 | Usage error | Fix call site |

---

## Verification

End-to-end pass on a throwaway bead pair confirmed:

| Criterion | Mechanism | Verified |
|---|---|---|
| 1. Ready-picker excludes human-labeled beads | `bd ready --exclude-label human` | ✓ |
| 2. Dual-write helper (comment + label, single step) | `bd-ask-human` | ✓ |
| 3. `bd human respond` resolves the pause | works via manual form; upstream bug filed | ✓ |
| 4. Callable from /stf-implement and /stf-loop | standalone CLI on PATH | ✓ |
| 5. Retry-then-escalate (6qk): 2 failures → blocked + excluded | `bd-loop-fail` exit 1 on N≥MAX; bead absent from `bd ready --exclude-label human` | ✓ |
| 6. Under-limit attempt (6qk): exit 0, notes updated | `bd-loop-fail` exit 0 on N<MAX | ✓ |
