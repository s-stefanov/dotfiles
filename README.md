# Stefan's dotfiles

My personal dotfiles. These configure my shell, editors, git, and the various tools I use day-to-day across macOS and an Arch/WSL machine.

Originally forked from [holman/dotfiles](https://github.com/holman/dotfiles); now diverged enough that it's effectively its own thing.

## Layout

Everything is organized by topic. Each top-level directory groups all configuration for one tool or area — `git/`, `zsh/`, `system/`, `homebrew/`, `claude/`, and so on. Adding a new topic is just: make a directory, drop files in, done. The loader picks them up by filename — no registration step.

The conventions that drive the loader:

- **`bin/*`** — prepended to `$PATH`; drop executables here to make them globally available.
- **`topic/*.zsh`** — sourced into the shell on startup.
- **`topic/path.zsh`** — sourced first; expected to set up `$PATH` / `$MANPATH`.
- **`topic/completion.zsh`** — sourced last, after `compinit`, so completions register correctly.
- **`topic/install.sh`** — run by `script/install`. Uses `.sh` (not `.zsh`) so it is not auto-sourced.
- **`topic/*.symlink`** — symlinked into `$HOME` without the extension by `script/bootstrap` (e.g. `git/gitconfig.symlink` → `~/.gitconfig`).
- **`functions/*`** — added to `fpath` and autoloaded as zsh functions.

See `CLAUDE.md` for the full set of conventions, including load order subtleties.

## Install

```sh
git clone git@github.com:s-stefanov/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
script/bootstrap
```

`script/bootstrap` symlinks every `*.symlink` file into `$HOME` (prompting on conflicts) and, on macOS or Linux, runs `bin/dot` to install Homebrew dependencies and run each topic's installer.

`script/install` runs `brew bundle` against the root `Brewfile` and then executes every topic's `install.sh`.

`bin/dot` is the periodic-refresh script: it pulls the repo, installs/updates Homebrew (works on both macOS and Linux/WSL), and re-runs `script/install`. On macOS it also reapplies the defaults in `macos/`. Run it occasionally to keep things fresh.

## Machine-specific config

- **`~/.localrc`** — sourced first by `zshrc.symlink` if it exists. Secrets and per-machine env go here; intentionally outside the repo.
- **`git/gitconfig.local.symlink`** — generated from the `.example` during bootstrap (prompts for name/email). Gitignored.

## Credit

The topic-based structure and bootstrap scaffolding originate from [@holman](https://github.com/holman)'s [dotfiles](https://github.com/holman/dotfiles), which in turn drew on [@ryanb](https://github.com/ryanb)'s. Thanks to both.
