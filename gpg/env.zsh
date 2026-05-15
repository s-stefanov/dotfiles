if [[ "$DOTFILES_OS" == "wsl" ]]; then
    export GPG_TTY=$(tty)
    export GCM_CREDENTIAL_STORE=gpg
fi
