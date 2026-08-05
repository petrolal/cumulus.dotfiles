# ── SSH agent (persist across shells, don't spawn a new one every terminal) ──
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)" > /dev/null
fi
