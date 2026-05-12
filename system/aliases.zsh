# grc overides for ls
#   Made possible through contributions from generous benefactors like
#   `brew install coreutils`
if $(gls &>/dev/null)
then
  alias ls="gls -F --color"
  alias l="gls -lAh --color"
  alias ll="gls -l --color"
  alias la='gls -A --color'
fi

if $(eza &>/dev/null)
then
  alias ls="eza -F"
  alias l="eza -lAh"
  alias ll="eza -l"
  alias la="eza -A"
fi
