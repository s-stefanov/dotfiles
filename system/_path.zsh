# Detect OS once so other topics can branch on $DOTFILES_OS
# (macos | wsl | linux). Lives in _path.zsh so it loads before everything else.
case "$OSTYPE" in
  darwin*) export DOTFILES_OS=macos ;;
  linux*)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      export DOTFILES_OS=wsl
    else
      export DOTFILES_OS=linux
    fi
    ;;
esac

export PATH="./bin:$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:$ZSH/bin:$PATH"
export MANPATH="/usr/local/man:/usr/local/mysql/man:/usr/local/git/man:$MANPATH"
