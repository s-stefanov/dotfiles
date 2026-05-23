#!/bin/sh
#
# Homebrew
#
# Installs Homebrew on macOS or Linux/WSL. The official installer auto-detects
# the platform and chooses the correct prefix (/opt/homebrew, /usr/local, or
# /home/linuxbrew/.linuxbrew). Also runs `brew bundle` against the root
# Brewfile so the full toolchain is installed in one place.
#
# Skipped when DOTFILES_PROFILE=minimal — that profile uses the native package
# manager (see pacman/install.sh).

# Pick up DOTFILES_PROFILE so this self-guards under script/install too.
[ -r "$HOME/.localrc" ] && . "$HOME/.localrc"

if [ "$DOTFILES_PROFILE" = "minimal" ]; then
  exit 0
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "  Installing Homebrew for you."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Make brew available in this shell for the rest of the bootstrap
  for brew_candidate in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    if [ -x "$brew_candidate" ]; then
      eval "$("$brew_candidate" shellenv)"
      break
    fi
  done
fi

# Link keg-only formulas that we want in PATH
brew list | grep 'postgresql@' | xargs -I {} brew link {} --force 2>/dev/null

# Install everything declared in the root Brewfile.
DOTFILES_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
echo "› brew bundle"
brew bundle --file="$DOTFILES_ROOT/Brewfile"

exit 0
