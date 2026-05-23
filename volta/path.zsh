if (( $+commands[brew] )); then
  export PATH="$(brew --prefix volta)/bin:$PATH"
fi
