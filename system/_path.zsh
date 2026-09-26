# $DOTFILES_OS is detected in zsh/zshenv.symlink before any topic file loads.
# Interactive-only (this file is pass 3): ./bin on $PATH is fine for a shell
# you are sitting at, not for arbitrary automated invocations.
export PATH="./bin:$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:$PATH"
export MANPATH="/usr/local/man:/usr/local/mysql/man:/usr/local/git/man:$MANPATH"
