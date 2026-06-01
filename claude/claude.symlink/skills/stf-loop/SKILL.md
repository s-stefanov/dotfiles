---
name: stf-loop
description: Drive the autonomous bd-integrated implementation loop for a bd epic. Use when the user types `/stf-loop <epic-id>` to automatically burn down all ready work in an epic by spawning a bd-worker subagent per bead, with termination checks, failure escalation, and human checkpoints. Do NOT invoke for one-off tasks — use /stf-implement directly for single beads.
---

# stf-loop

Autonomous loop driver for a bd epic. Spawns a `bd-worker` subagent per ready descendant of the given epic, handling failure via `bd-loop-fail`, human checkpoints via `stf-checkpoint`, and termination via `stf-loop-termcheck`. Runs all beads in-session for attended use; uses ScheduleWakeup for unattended continuation.

## Arguments

```
/stf-loop <epic-id> [--unattended] [--max-failures N] [--max-iterations N]
```

- `<epic-id>` — required. The bd epic to scope the loop to.
- `--unattended` — set by ScheduleWakeup re-invocations only. Do NOT pass manually.
- `--max-failures N` — max consecutive failures per bead before escalation (default 2, forwarded to `bd-loop-fail`).
- `--max-iterations N` — hard cap on total loop passes (default 100); triggers circuit-breaker exit when `iter_count` reaches this limit.

## State file

Maintain a per-epic state file at `.claude/stf-loop.<epic-id>.local.md`. Before creating the file, ensure `stf-loop.*.local.md` is in the project's `.gitignore` (add the line if absent). Format:

```
---
epic_id: <epic-id>
iter_count: 0
max_iterations: 100
max_failures: 2
last_decision: ""
last_pass_ts: ""
---
```

Initialize on first run if absent. Default `max_iterations` to 100 if missing (backward compat with pre-84v state files). Update `iter_count`, `last_decision`, and `last_pass_ts` after each pass.

## Execution modes

### Attended mode (no `--unattended` flag)

Run all beads sequentially **in this session** — no ScheduleWakeup between beads:

```
LOOP:
  → Step 0.5: snapshot + circuit-breaker check
  → if CB tripped: Step 5 (stop, no ScheduleWakeup)
  → Step 1: termination check
  → if continue: Step 2 (pick) → Step 3 (implement) → Step 4 (outcome) → goto LOOP
  → if terminal (complete / waiting-on-human / error): Step 5 (stop, no ScheduleWakeup)
```

Burn down all ready beads without pausing between them. Only stop at a terminal decision or session end.

### Unattended mode (`--unattended` flag)

Single bead per invocation, then yield:

```
  → Step 0.5: snapshot + circuit-breaker check
  → if CB tripped: Step 5 (stop, no ScheduleWakeup)
  → Step 1: termination check
  → if continue: Step 2 → Step 3 → Step 4 → Step 5 (ScheduleWakeup for next pass)
  → if terminal: Step 5 (stop, no ScheduleWakeup)
```

## Per-pass algorithm

### Step 0: Initialize

Parse `<epic-id>` from ARGUMENTS. Detect `--unattended` flag.

Load or initialize state file. Parse `--max-failures N` (default 2). Parse `--max-iterations N` (default 100); store in state file (default if missing for backward compat).

### Step 0.5: Live snapshot + circuit-breaker check

Run termcheck **once** to get the live bd state. Use its output for both the snapshot (below) and Step 1 (no need to re-run):

```bash
TERM_JSON=$(stf-loop-termcheck <epic-id>)
TERM_EXIT=$?
```

Compute the open/in_progress split from `remaining_ids` (non-human open+in_progress beads):

```bash
REMAINING_IDS=$(echo "$TERM_JSON" | python3 -c "
import json,sys
d=json.load(sys.stdin)
ids=d.get('remaining_ids',[])
print(','.join(ids) if ids else '')
")

if [[ -n "$REMAINING_IDS" ]]; then
  OPEN_COUNT=$(bd list --id "$REMAINING_IDS" --status open --json 2>/dev/null \
    | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" || echo 0)
  IP_COUNT=$(bd list --id "$REMAINING_IDS" --status in_progress --json 2>/dev/null \
    | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" || echo 0)
else
  OPEN_COUNT=0
  IP_COUNT=0
fi

HUMAN_COUNT=$(echo "$TERM_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['human_pending'])")
SNAPSHOT="epic=${EPIC_ID} iter=${ITER_COUNT}/${MAX_ITERATIONS} open=${OPEN_COUNT} in_progress=${IP_COUNT} human=${HUMAN_COUNT}"
```

Emit the snapshot line:
```
[stf-loop]   snapshot: epic=<id> iter=<N>/<MAX> open=<X> in_progress=<Y> human=<Z>
```

**Circuit-breaker check** — fire before any work dispatch:

```bash
if [[ "$ITER_COUNT" -ge "$MAX_ITERATIONS" ]]; then
  echo "[stf-loop] STOPPED: circuit-breaker"
  echo "  circuit breaker tripped at ${ITER_COUNT}/${MAX_ITERATIONS}"
  echo "  Pass count: ${ITER_COUNT}"
  # Write state, no ScheduleWakeup
  update_state last_decision=circuit-breaker last_pass_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  exit 0
fi
```

### Step 1: Termination check

Use `TERM_JSON` / `TERM_EXIT` already computed in Step 0.5 (no re-run needed).

Emit one line: `[stf-loop] pass <N> epic=<epic-id> attended=<true|false> => <decision>`

Act on `TERM_EXIT`:

| Exit | Decision | Action |
|---|---|---|
| 0 | `continue` | Proceed to Step 2 |
| 10 | `complete` | Print stop summary, update state `last_decision=complete`, go to Step 5 (terminal) |
| 11 | `waiting-on-human` | Print stop summary + human bead IDs from JSON, update state, go to Step 5 |
| 2 | error | Print error message, go to Step 5 (terminal) |

### Step 2: Pick target bead

`bd ready` sorts by priority then age and is the authoritative ready-picker. Try it first:

```bash
TARGET_JSON=$(bd ready --parent <epic-id> --exclude-label human --json --limit 1)
TARGET=$(echo "$TARGET_JSON" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d[0]['id'] if d else '')
")
```

If `TARGET` is empty (bead is `in_progress` from an interrupted prior session — `bd ready` excludes in_progress; blocked beads are also excluded):

```bash
# Fall back: find the first in_progress bead among termcheck's remaining_ids
TARGET=$(echo "$TERM_JSON" | python3 -c "
import json, sys, subprocess
d = json.load(sys.stdin)
for bid in d.get('remaining_ids', []):
    try:
        out = subprocess.check_output(['bd', 'show', bid, '--json'], stderr=subprocess.DEVNULL)
        item = json.loads(out)
        item = item[0] if isinstance(item, list) else item
        if item.get('status') == 'in_progress':
            print(bid)
            break
    except Exception:
        pass
")
```

If `TARGET` is still empty: log warning and skip this pass (loop state is inconsistent; termcheck will re-evaluate next time). In unattended mode, schedule a short ScheduleWakeup (60s) and stop.

Emit: `[stf-loop]   target: <TARGET>`

### Step 3: Invoke bd-worker subagent

Spawn a fresh subagent context per bead. Capture the return value for Step 4:

```
SUBAGENT_RETURN = Agent(subagent_type='bd-worker', prompt='<TARGET>\n[loop-snapshot] <SNAPSHOT>')
```

Putting the bead ID first preserves bd-worker's arg-parsing (reads first token as the ID). The `[loop-snapshot]` line is context-only — it orients the subagent within the loop's current state without influencing the ready-picker or termination check.

### Step 4: Evaluate outcome

After the subagent returns, parse the optional JSON return for routing hints, then read authoritative status from bd.

**Parse subagent JSON return (best-effort):**

Scan `SUBAGENT_RETURN` for the last JSON object containing a `status` key (last-match rule handles markdown noise and multiple `{...}` fragments):

```bash
SUBAGENT_JSON=$(python3 -c "
import json, sys
raw = sys.stdin.read()
decoder = json.JSONDecoder()
result = None
i = 0
while i < len(raw):
    try:
        obj, end = decoder.raw_decode(raw, i)
        if isinstance(obj, dict) and 'status' in obj:
            result = json.dumps(obj)
        i = end
    except Exception:
        i += 1
print(result or '')
" 2>/dev/null <<< "$SUBAGENT_RETURN")
```

Extract routing fields:

```bash
if [[ -n "$SUBAGENT_JSON" ]]; then
    Q_ID=$(echo "$SUBAGENT_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin).get('question_bead',''))" 2>/dev/null || echo "")
    FILES_CHANGED=$(echo "$SUBAGENT_JSON" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin).get('files_changed',[])))" 2>/dev/null || echo "[]")
else
    echo "[stf-loop]   parse-failure: JSON extraction failed, falling back to bd status"
    Q_ID=""
    FILES_CHANGED="unknown"
fi
```

**Read authoritative status from bd (bd is source of truth; JSON is routing aid):**

```bash
STATUS=$(bd show <TARGET> --json \
  | python3 -c "import json,sys; d=json.load(sys.stdin); item=d[0] if isinstance(d,list) else d; print(item.get('status',''))")
```

**Log files_changed for observability** (always, even when `unknown` from a parse failure):

```
[stf-loop]   files_changed: <FILES_CHANGED>
```

**`closed`** — success:
- Emit `[stf-loop]   outcome: closed`

**Not `closed`** — distinguish human-gate from failure. Primary signal: `Q_ID` from JSON `question_bead`. Fallback when JSON parse failed or `question_bead` absent: check bd for any blocker:

```bash
if [[ -z "$Q_ID" ]]; then
    Q_ID=$(bd show <TARGET> --json | python3 -c "
import json,sys
d=json.load(sys.stdin)
item=d[0] if isinstance(d,list) else d
blockers = item.get('blockers',[]) or []
print(blockers[0] if blockers else '')
" 2>/dev/null || echo "")
fi
```

If `Q_ID` is non-empty → human gate (`stf-checkpoint` already dual-wrote inside the subagent; next pass will skip the blocked bead):
- Emit `[stf-loop]   outcome: human-gate on <TARGET> → <Q_ID> awaiting`

If `Q_ID` is still empty → implementation failure:

```bash
SUMMARY="bd-worker did not close bead <TARGET> (status: $STATUS)"
bd-loop-fail <TARGET> "$SUMMARY" --max <max-failures>
FAIL_EXIT=$?
```

- Exit 0: recorded, retry next pass. Emit `[stf-loop]   outcome: failure-recorded (will retry)`.
- Exit 1: escalated, bead now human-labeled and blocked. Emit `[stf-loop]   outcome: escalated (human-labeled)`.

**After all outcome branches** — increment the pass counter unconditionally (counts every subagent invocation, regardless of outcome):

```bash
ITER_COUNT=$((ITER_COUNT + 1))
# Write updated iter_count and last_pass_ts to state file
```

### Step 5: Continue or stop

**Terminal decision (complete / waiting-on-human / circuit-breaker / error):**

Print a stop summary:
```
[stf-loop] STOPPED: <decision>
  Reason: <detail from termcheck JSON>
  Pass count: <iter_count>
  Human pending: <human_ids from JSON, if waiting-on-human>
```

For `circuit-breaker`: the exit is already printed and handled in Step 0.5 before reaching here. The message must contain "circuit breaker tripped at N/MAX" per AC1.

Write `last_decision` and `last_pass_ts` to state file. On `complete` or `waiting-on-human`, delete the state file — these are clean terminations; `iter_count` resets on re-launch so each loop cycle starts with a fresh counter. On `circuit-breaker` or `error`, keep the state file so the count is visible for debugging; manual delete resets the CB counter for the next run.

For `waiting-on-human` in unattended mode: schedule a long-poll wakeup:
```
ScheduleWakeup(delaySeconds=1800, prompt="/stf-loop <epic-id> --unattended", reason="waiting on human in epic <epic-id>")
```

For `waiting-on-human` in attended mode: stop (user is present; they'll act on the question bead and re-launch).

No ScheduleWakeup for `complete`, `circuit-breaker`, or `error`.

**Attended mode, continue:** loop back to Step 1 immediately.

**Unattended mode, continue:** schedule next pass:
```
ScheduleWakeup(delaySeconds=270, prompt="/stf-loop <epic-id> --unattended", reason="next bead in epic <epic-id>")
```

Then stop this invocation.

## What stf-loop does NOT do

- **No brainstorm or plan automation** — issues must already exist in bd before launching the loop.
- **No ideation** — it executes existing ready work, it does not create or design work.
- **No parallelism** — one bead per pass, sequential execution. A worktree-parallel variant is a separate epic.
- **No Codex** — Claude Code only.
- **No scope inference** — provide an explicit `<epic-id>`; the loop does not discover or create epics.

## Observability

Each pass emits to stdout:
```
[stf-loop] pass <N> epic=<id> attended=<true|false> => <decision>
[stf-loop]   snapshot: epic=<id> iter=<N>/<MAX> open=<X> in_progress=<Y> human=<Z>
[stf-loop]   target: <bead-id>
[stf-loop]   files_changed: <["path/a","path/b"]|[]|unknown>
[stf-loop]   outcome: <closed|human-gate on <TARGET> → <Q_ID> awaiting|failure-recorded|escalated>
```

`files_changed` is `unknown` when JSON parse failed; `[]` when the subagent made no file changes.

Terminal stop:
```
[stf-loop] STOPPED: <complete|waiting-on-human|circuit-breaker|error>
  Reason: <detail>
  Pass count: <N>
  Human pending: <IDs, if applicable>
```

Circuit-breaker stop (emitted from Step 0.5 before Step 1):
```
[stf-loop] STOPPED: circuit-breaker
  circuit breaker tripped at <N>/<MAX>
  Pass count: <N>
```

All of the above is also captured in the state file's `last_decision` and in bd notes/comments via the primitives (`bd-loop-fail`, `stf-checkpoint`).

## Idempotency

Re-launching `/stf-loop <epic-id>` is safe at any point:

- All authoritative state is in bd — no in-memory cursor to resume from.
- Termination check re-queries bd fresh each pass.
- `bd ready --parent` returns open beads; the `in_progress` fallback (Step 2) handles beads interrupted mid-session.
- `bd update --claim` inside bd-worker is idempotent if the bead is already in_progress.
- `iter_count` accumulates across ScheduleWakeup-driven re-invocations (unattended mode) so the CB fires at the right point even if the loop spans multiple wakeups. It resets each loop cycle — the state file is deleted on clean termination (`complete` / `waiting-on-human`) or manual delete.
