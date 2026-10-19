# Homebrew Ruby's gem bin dir. Globbed so it survives Ruby version bumps and
# works on both macOS (/opt/homebrew) and Linuxbrew; no `gem env` fork. Relies
# on homebrew/path.zsh (sorts earlier) having set $HOMEBREW_PREFIX.
(( $+HOMEBREW_PREFIX )) && path+=($HOMEBREW_PREFIX/lib/ruby/gems/*/bin(N))
