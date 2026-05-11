# Initialize brew from /opt/homebrew (Apple Silicon) or
# /home/linuxbrew/.linuxbrew (Linux/WSL).
for brew_candidate in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
  if [ -x "$brew_candidate" ]; then
    eval "$("$brew_candidate" shellenv)"
    break
  fi
done
unset brew_candidate
