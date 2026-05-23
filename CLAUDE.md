# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal dotfiles, forked from holman/dotfiles. Topic-based layout: each top-level directory (e.g. `git/`, `zsh/`, `system/`, `homebrew/`) groups all configuration for one tool or area.

## Setup commands

- `script/bootstrap` — prompts for `$DOTFILES_PROFILE` on first run, symlinks every `*.symlink` file into `$HOME` (without the extension, filtered by the active profile's `topics` allow-list), and, on macOS or Linux, runs `bin/dot`. Prompts on conflicts (skip / overwrite / backup, with "all" variants).
- `script/install` — sources `~/.localrc`, then executes every `install.sh` it can find (`find . -name install.sh`). Each installer self-guards on `$DOTFILES_PROFILE` and `command -v <its-package-manager>` so the same loop works across profiles. `brew bundle` lives inside `homebrew/install.sh`.
- `bin/dot` — periodic refresh: `git pull` the dotfiles repo, on macOS also runs `macos/set-defaults.sh` and `macos/set-hostname.sh`. On `full` it ensures Homebrew via `homebrew/install.sh` and runs `brew update && brew upgrade`; on `minimal` it runs `sudo pacman -Syu` instead. Then `script/install`. `dot -e` opens the repo in `$EDITOR`.

## File-extension conventions (load order matters)

`zsh/zshrc.symlink` globs `$ZSH/**/*.zsh` and sources files in this order — naming is the dispatch mechanism, so be careful when adding files:

1. `**/path.zsh` — sourced first, expected to set `$PATH`/`$MANPATH`. `system/_path.zsh` is the canonical one (the leading underscore makes it sort before any sibling `path.zsh`, but it still matches the `*/path.zsh` glob).
2. Everything else ending in `.zsh` (except `path.zsh` and `completion.zsh`).
3. `compinit` runs.
4. `**/completion.zsh` — sourced last so completions register after `compinit`.

Other conventions:

- `topic/*.symlink` → symlinked to `$HOME/.<basename-without-ext>` by `script/bootstrap` (e.g. `git/gitconfig.symlink` → `~/.gitconfig`). Only files at depth ≤ 2 are picked up (`-maxdepth 2`).
- If a `*.symlink` is a **directory** (e.g. `claude/claude.symlink/`), bootstrap creates `$HOME/.<name>` as a real directory and symlinks each child file individually into it. This lets a topic ship a populated dotdirectory without clobbering anything the user adds locally to that same dir.
- `topic/install.sh` → executed by `script/install`. Use `.sh` (not `.zsh`) so it does NOT get auto-sourced into the shell.
- `bin/*` is prepended to `$PATH` via `system/_path.zsh`; drop executables here to make them globally available.
- `functions/*` is added to `fpath` and autoloaded (`zsh/config.zsh`); files are zsh autoload functions, not scripts — no shebang, just the function body.
- `zsh/fpath.zsh` also adds every top-level topic directory to `fpath`, so any topic can ship completion functions or autoloaded functions alongside its `.zsh` files.

## OS detection: `$DOTFILES_OS`

`system/_path.zsh` exports `$DOTFILES_OS` to one of `macos`, `wsl`, or `linux` (WSL is detected by grepping `/proc/version` for `microsoft`). Because `_path.zsh` is sourced in the first pass, every other `.zsh` file can branch on it. This is the canonical way to do OS-specific config — see `system/keys.zsh` (clipboard alias per OS), `gpg/path.zsh` and `podman/env.zsh` (WSL-only paths), and `xcode/aliases.zsh` (macOS-only). Prefer `$DOTFILES_OS` over re-running `uname` in each topic.

## Profiles: `$DOTFILES_PROFILE`

Independent of OS, `$DOTFILES_PROFILE` selects how much of the dotfiles applies to a given machine:

- **`full`** (default) — every topic, full Brewfile, dev tooling, GUI casks. macOS workstations and the Arch/WSL dev box.
- **`minimal`** — shell + terminal goodies only, native packages via `pacman`. Headless boxes (e.g. the Arch home server). No dev tooling, no GUI apps.

The discriminator is **purpose**, not OS — WSL Arch runs `full`, the home-server Arch runs `minimal`.

How it works:

- `script/bootstrap` prompts on first run and persists `export DOTFILES_PROFILE=<choice>` to `~/.localrc`. `bin/dot`, `script/install`, and every `install.sh` re-source `~/.localrc` so non-login shells see it too.
- `profiles/<name>/topics` — allow-list of top-level topic directories. `script/bootstrap` skips any `*.symlink` whose topic dir is not listed. Absent file (i.e. `full`) = no filter.
- `profiles/<name>/<manager>` — manifest of native packages (one per line, `#` comments allowed). `pacman/install.sh` reads `profiles/$DOTFILES_PROFILE/pacman`.
- Each topic's `install.sh` self-guards (e.g. `homebrew/install.sh` early-returns when `$DOTFILES_PROFILE = minimal`; `pacman/install.sh` early-returns when there's no manifest for the active profile). `script/install` stays a uniform `find . -name install.sh` loop.
- `$DOTFILES_EXTRA_TOPICS` (space-separated, set in `~/.localrc`) is additive to the profile's `topics` list — escape hatch for pulling in one extra topic on a minimal box without editing the manifest.

Topic `.zsh` files are **not** filtered by profile — they self-guard via `command -v` (e.g. `system/grc.zsh`, `volta/*.zsh`, `git/completion.zsh`). Filtering at the zsh layer would couple shell startup to the profile concept and cost more than it would buy.

See `profiles/README.md` for the manifest format and how to add a profile.

## Local / machine-specific config

- `~/.localrc` — sourced first by `zshrc.symlink` if present. Put secrets and machine-specific env here; it is intentionally outside the repo.
- `git/gitconfig.local.symlink` — generated by `script/bootstrap` from `gitconfig.local.symlink.example` (prompts for name/email, picks `osxkeychain` on Darwin). Gitignored. The committed `gitconfig.symlink` `[include]`s it.

## Adding a new topic

To add e.g. a `rust` topic: create `rust/`, drop `aliases.zsh` / `env.zsh` / `path.zsh` as needed, add `rust/install.sh` if it needs install steps, and any `rust/*.symlink` for dotfiles. No registration step — the loader picks it up by filename.

## macOS vs other platforms

`script/bootstrap` runs `bin/dot` on both Darwin and Linux (Homebrew is installed on both via `homebrew/install.sh`). The macOS-specific bits — `macos/set-defaults.sh` and `macos/set-hostname.sh` — are gated inside `bin/dot` by a `uname -s == Darwin` check.
