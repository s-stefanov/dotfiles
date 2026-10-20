# grc overides for ls
#   Made possible through contributions from generous benefactors like
#   `brew install coreutils`
if (( $+commands[gls] ))
then
  alias ls="gls -F --color"
  alias l="gls -lAh --color"
  alias ll="gls -l --color"
  alias la='gls -A --color'
fi

if (( $+commands[eza] ))
then
  alias ls="eza -F"
  alias l="eza -lAh"
  alias ll="eza -l"
  alias la="eza -A"
fi

if (( $+commands[orca-ide] ))
then
  alias orca="orca-ide"
fi
