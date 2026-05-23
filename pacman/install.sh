#!/bin/sh
#
# pacman
#
# Installs native packages from profiles/$DOTFILES_PROFILE/pacman. Self-guards:
# only runs when DOTFILES_PROFILE is set to a profile that ships a pacman
# manifest AND `pacman` is on PATH.

# Pick up DOTFILES_PROFILE from ~/.localrc when run outside an interactive shell.
[ -r "$HOME/.localrc" ] && . "$HOME/.localrc"

if ! command -v pacman >/dev/null 2>&1; then
  exit 0
fi

DOTFILES_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
manifest="$DOTFILES_ROOT/profiles/${DOTFILES_PROFILE:-full}/pacman"

if [ ! -r "$manifest" ]; then
  exit 0
fi

packages=$(sed -e 's/#.*$//' -e '/^[[:space:]]*$/d' "$manifest" | tr '\n' ' ')

if [ -z "$packages" ]; then
  exit 0
fi

echo "› sudo pacman -S --needed $packages"
# shellcheck disable=SC2086
sudo pacman -S --needed $packages
