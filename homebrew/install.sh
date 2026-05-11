#!/bin/sh
#
# Homebrew
#
# Installs Homebrew on macOS or Linux/WSL. The official installer auto-detects
# the platform and chooses the correct prefix (/opt/homebrew, /usr/local, or
# /home/linuxbrew/.linuxbrew).

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

exit 0
