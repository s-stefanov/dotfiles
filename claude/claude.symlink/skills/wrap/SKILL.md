---
name: wrap
description: Close out a work session cleanly. Use when the user says they're done, wants to wrap up, end the session, finish, or hand off. Closes completed bd issues, runs quality gates, files follow-ups, syncs bd, pushes git, and writes a handoff. Work is not complete until changes are pushed (when a remote exists).
---

# Wrap

End-of-session protocol. The tail of the workflow; `/prime-session` resumes from where this leaves off.

> **Assumes bd is initialized here.** If the repo has no `.beads/`, skip the bd steps and just run the git/quality-gate/handoff steps. bd is the source of truth for this workflow.

## Mandatory steps

1. **File follow-ups**: create bd issues for anything discovered or left unfinished — don't let it live only in chat.
2. **Quality gates** (if code changed): run tests, linters, and build. Fix or file failures; don't leave the tree broken.
3. **Update issue status**: `bd close <id1> <id2> …` for finished work; update notes on anything still in progress.
4. **Sync + push**:
   - bd data: `bd dolt push` — **only if a beads remote is configured**.
   - code: `git pull --rebase && git push` — **only if a git remote exists**.
   - If the repo is local-only, skip pushing and **say so explicitly**. Never claim work was pushed when there is no remote.
5. **Clean up**: clear stashes; prune merged branches and finished worktrees.
6. **Verify**: `git status` shows clean / up to date with origin (when a remote exists).
7. **Hand off**: short summary — what got done, what's in flight, and the suggested entry point for next session (usually `/prime-session`).

## Critical rules

- When a remote exists, **work is not complete until `git push` succeeds**. If push fails, resolve and retry until it does.
- Never stop before pushing; never say "ready to push when you are" — do the push.
