# Profiles

`$DOTFILES_PROFILE` controls which subset of the dotfiles applies to the current machine. It is set in `~/.localrc` (`script/bootstrap` prompts on first run) and defaults to `full`.

## Profiles

- **`full`** (default) — every topic, full `Brewfile`, GUI casks, dev tooling. Used on macOS workstations and the Arch/WSL dev box.
- **`minimal`** — shell + terminal goodies only, native packages via `pacman`. Used on headless boxes (e.g. the Arch home server) where dev tooling and GUI apps are not wanted.

## Contract

Each profile directory under `profiles/<name>/` is a set of plain-text manifests:

- **`topics`** — one topic directory name per line. Acts as an allow-list for `script/bootstrap` when symlinking `*.symlink` files: anything whose top-level directory is not in the list is skipped. Absent file = no filter (the `full` default).
- **`pacman`** — one package per line. Read by `pacman/install.sh` and passed to `sudo pacman -S --needed`. Comments (`# …`) and blank lines are ignored.

Other package managers can follow the same convention: drop a `profiles/<name>/<manager>` file and a sibling `<manager>/install.sh` that reads it. Every `install.sh` is expected to self-guard on `$DOTFILES_PROFILE` (and on `command -v <manager>`), so adding a new one is purely additive.

## Escape hatch

`$DOTFILES_EXTRA_TOPICS` (space-separated, set in `~/.localrc`) is additive to the profile's `topics` list. Lets a minimal box pull in one extra topic without editing the manifest.

## Adding a profile

1. Create `profiles/<name>/topics` listing the allowed topic dirs.
2. Create `profiles/<name>/<manager>` manifests for any native package managers it uses.
3. If a new package manager is involved, add `<manager>/install.sh` that early-returns unless `$DOTFILES_PROFILE` matches and `command -v <manager>` succeeds.
4. Make sure every existing topic `install.sh` you care about self-guards (e.g. `homebrew/install.sh` early-returns on `minimal`).
