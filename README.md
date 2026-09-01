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

`script/bootstrap` symlinks every `*.symlink` file into `$HOME` (prompting on conflicts) and, on macOS or Linux, runs `bin/dot` to install dependencies and run each topic's installer. On first run it also prompts for a profile (see below).

`script/install` runs every topic's `install.sh`. Each installer self-guards on profile and on the presence of its package manager — `brew bundle` is inside `homebrew/install.sh`, native package installs are inside `pacman/install.sh`.

`bin/dot` is the periodic-refresh script: it pulls the repo and, on the `full` profile, installs/updates Homebrew (works on both macOS and Linux/WSL). On `minimal` it runs `sudo pacman -Syu` instead. Then re-runs `script/install`. On macOS it also reapplies the defaults in `macos/`. Run it occasionally to keep things fresh.

## Minimal install

On first run, `script/bootstrap` asks which profile this machine should use:

- **`full`** (default) — every topic, full `Brewfile`, dev tooling, GUI casks. macOS workstations and the dev Arch/WSL box.
- **`minimal`** — shell + terminal goodies (`zsh`, `git`, `tmux`, `fzf`, `eza`, `grc`, `zoxide`, `atuin`, `starship`, `vim`, `neovim`) installed via `pacman`. No dev tooling, no GUI casks. Intended for headless boxes like the Arch home server.

The choice is persisted as `export DOTFILES_PROFILE=<choice>` in `~/.localrc`. To switch profiles later, edit that line. To pull in one extra topic on a minimal box without editing the manifest, add `export DOTFILES_EXTRA_TOPICS="docker podman"` to `~/.localrc`. See `profiles/README.md` for the manifest format.

## Machine-specific config

- **`~/.localrc`** — sourced first by `zshenv.symlink` if it exists, so it's available to every shell, not just interactive ones. Secrets and per-machine env go here; intentionally outside the repo.
- **`git/gitconfig.local.symlink`** — generated from the `.example` during bootstrap (prompts for name/email). Gitignored.

## Credit

The topic-based structure and bootstrap scaffolding originate from [@holman](https://github.com/holman)'s [dotfiles](https://github.com/holman/dotfiles), which in turn drew on [@ryanb](https://github.com/ryanb)'s. Thanks to both.
