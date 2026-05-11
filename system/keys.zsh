# Pipe my public key to my clipboard.
case "$DOTFILES_OS" in
  macos)
    alias pubkey="more $HOME/.ssh/id_ed25519.pub | pbcopy | echo '=> Public key copied to pasteboard.'"
    ;;
  wsl)
    alias pubkey="more $HOME/.ssh/id_ed25519.pub | clip.exe && echo '=> Public key copied to pasteboard.'"
    ;;
  linux)
    if (( $+commands[wl-copy] )); then
      alias pubkey="more $HOME/.ssh/id_ed25519.pub | wl-copy && echo '=> Public key copied to pasteboard.'"
    elif (( $+commands[xclip] )); then
      alias pubkey="more $HOME/.ssh/id_ed25519.pub | xclip -selection clipboard && echo '=> Public key copied to pasteboard.'"
    fi
    ;;
esac
