#!/usr/bin/env bash
#
# runtime-refresh.sh — refresh supported running applications after a theme
# change. Adapters are best-effort: persisted theme state remains authoritative
# when an application is unavailable or has no safe runtime endpoint.
#
# Usage:
#   ./runtime-refresh.sh
#
set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(cd "$(dirname "$SELF")/.." && pwd)"
STATE_FILE="$HOME/.config/cumulus/theme/state"
CURRENT_USER="$(id -un)"
REFRESHED_COUNT=0
DEFERRED_COUNT=0

log() { printf '\033[1;35m[theme-refresh]\033[0m %s\n' "$*"; }

run_adapter() {
  local name="$1"; shift
  if "$@"; then
    log "$name: refreshed"
    REFRESHED_COUNT=$((REFRESHED_COUNT + 1))
  else
    log "$name: deferred or unavailable"
    DEFERRED_COUNT=$((DEFERRED_COUNT + 1))
  fi
}

refresh_sway() {
  command -v swaymsg >/dev/null 2>&1 || return 1
  swaymsg -t get_version >/dev/null 2>&1 || return 1
  swaymsg reload >/dev/null 2>&1
}

refresh_waybar() {
  command -v pgrep >/dev/null 2>&1 || return 1
  pgrep -x waybar >/dev/null 2>&1 || return 1
  pkill -USR2 -x waybar >/dev/null 2>&1
}

refresh_kitty() {
  command -v kitty >/dev/null 2>&1 || return 1
  local socket="${CUMULUS_KITTY_SOCKET:-${XDG_RUNTIME_DIR:-/tmp}/cumulus-kitty}"
  [ -S "$socket" ] || return 1
  [ "$(stat -c '%U' "$socket" 2>/dev/null || true)" = "$CURRENT_USER" ] || return 1
  kitty @ --to "unix:$socket" set-colors --all --configured \
    "$DOTFILES_DIR/config/kitty/colors.conf" >/dev/null 2>&1
}

refresh_wofi() {
  # Wofi is a short-lived launcher; its generated CSS is read on next launch.
  pgrep -x wofi >/dev/null 2>&1 && pkill -TERM -x wofi >/dev/null 2>&1 || return 1
}

refresh_nvim_socket() {
  local socket="$1"
  [ -S "$socket" ] || return 1
  [ "$(stat -c '%U' "$socket" 2>/dev/null || true)" = "$CURRENT_USER" ] || return 1
  timeout 5s nvim --headless --server "$socket" \
    --remote-send '<Cmd>lua require("cumulus.theme").load_saved_theme()<CR>' \
    >/dev/null 2>&1
}

refresh_nvim() {
  command -v nvim >/dev/null 2>&1 || return 1
  local found=false refreshed=false socket
  local -a sockets=()
  shopt -s nullglob
  [ -n "${XDG_RUNTIME_DIR:-}" ] && sockets+=("$XDG_RUNTIME_DIR"/nvim/*.sock)
  sockets+=("${TMPDIR:-/tmp}"/nvim.*.sock /tmp/nvim.*.sock)
  for socket in "${sockets[@]}"; do
    [ -e "$socket" ] || continue
    found=true
    if refresh_nvim_socket "$socket"; then
      refreshed=true
    else
      log "neovim: unreachable or rejected socket $(basename "$socket")"
    fi
  done
  shopt -u nullglob
  $found && $refreshed
}

main() {
  [ -f "$STATE_FILE" ] || { log "No theme state; nothing to refresh."; exit 0; }
  run_adapter "sway" refresh_sway
  run_adapter "waybar" refresh_waybar
  run_adapter "kitty" refresh_kitty
  run_adapter "wofi" refresh_wofi
  run_adapter "neovim" refresh_nvim
  run_adapter "os/gtk" "$DOTFILES_DIR/scripts/os-colorscheme.sh"
  run_adapter "rgb" "$DOTFILES_DIR/scripts/rgb-theme.sh"
  if [ "$DEFERRED_COUNT" -eq 0 ]; then
    log "Refresh result: complete ($REFRESHED_COUNT adapters refreshed)"
  else
    log "Refresh result: partial ($REFRESHED_COUNT refreshed, $DEFERRED_COUNT deferred)"
  fi
}

main "$@"
