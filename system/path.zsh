# WSL appends ~40 slow 9P /mnt/c dirs to $PATH; every command-hash lookup scans
# them (~1.5s per interactive shell). Drop them; clip.exe is called by full path.
[[ $DOTFILES_OS == wsl ]] && path=(${path:#/mnt/*})
