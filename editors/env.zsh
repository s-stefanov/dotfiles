# Pick the first available editor. zed for graphical sessions, then fall back
# through nvim → vim → nano so `git commit`, `crontab -e`, etc. work on a
# headless server.
for editor in zed nvim vim nano; do
  if (( $+commands[$editor] )); then
    export EDITOR="$editor"
    break
  fi
done
