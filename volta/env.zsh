if (( $+commands[brew] )); then
  export VOLTA_HOME=$(brew --prefix volta)
  export VOLTA_FEATURE_PNPM=1
fi
