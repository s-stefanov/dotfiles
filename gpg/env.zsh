if [[ "$DOTFILES_OS" == "wsl" ]]; then
    # -t 0 guard: `tty` prints the literal string "not a tty" (not an error)
    # when there's no controlling terminal, e.g. non-interactive shells now
    # that this file loads via .zshenv.
    if [[ -t 0 ]]; then
        export GPG_TTY=$(tty)
    fi
    export GCM_CREDENTIAL_STORE=gpg
fi
