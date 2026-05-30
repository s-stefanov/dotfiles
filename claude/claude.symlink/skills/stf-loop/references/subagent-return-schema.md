# Subagent Return Schema

Defines the JSON object that `stf-implement` (when invoked as a subagent) must emit as its **final output**. The loop's Step 4 parses this for routing; bd is the authoritative state — JSON is observability and routing sugar, not a replacement.

## Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `status` | string | yes | One of `closed`, `human-gate`, `failure` |
| `summary` | string | yes | One-line human-readable outcome description |
| `question_bead` | string | if `human-gate` | bd bead ID of the created question bead (e.g. `epic-xyz.Q1`) |
| `files_changed` | string[] | yes | Relative paths of files modified; empty array if none |

## Allowed `status` Values

- **`closed`** — the work bead was verified and closed by stf-implement.
- **`human-gate`** — stf-implement hit a decision it could not resolve autonomously. A human-labeled question bead was created via `stf-checkpoint` and the work bead is now blocked on it.
- **`failure`** — stf-implement could not complete the work (test failure, error, etc.) and did not close the bead.

## Examples

### `closed`

```json
{
  "status": "closed",
  "summary": "Implemented retry logic in bd-loop-fail and verified with unit tests.",
  "files_changed": ["bin/bd-loop-fail", "tests/test_bd_loop_fail.sh"]
}
```

### `human-gate`

```json
{
  "status": "human-gate",
  "summary": "Blocked on ambiguous acceptance criterion — created question bead for human input.",
  "question_bead": "personal-dev-workflow-osn.Q1",
  "files_changed": []
}
```

### `failure`

```json
{
  "status": "failure",
  "summary": "Tests failed after implementation; root cause unclear without more context.",
  "files_changed": ["bin/stf-loop"]
}
```

## Parse-Failure Rule

The Agent tool returns free-form text. JSON extraction is **instructed, not harness-enforced**. If Step 4 cannot extract valid JSON from the subagent return:

1. **Do not block or error the loop.**
2. Fall back to `bd show <TARGET> --json` to read bead status directly.
3. Treat the outcome as if `status` matched the bd status (`closed` → success, `in_progress` or `open` → use human-blocker check to distinguish `human-gate` from `failure`).
4. Log a warning: `[stf-loop]   parse-failure: JSON extraction failed, falling back to bd status`.

bd is the source of truth; the JSON return is an optimization for routing clarity, not a hard requirement.
