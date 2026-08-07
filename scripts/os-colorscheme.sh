#!/usr/bin/env bash
#
# os-colorscheme.sh — synchronize the optional GNOME/GTK color-scheme setting.
#
# Unsupported desktops are intentionally reported as deferred, not fatal.
#
set -euo pipefail

STATE_FILE="$HOME/.config/cumulus/theme/state"

log() { printf '\033[1;35m[os-theme]\033[0m %s\n' "$*"; }

main() {
  command -v gsettings >/dev/null 2>&1 || {
    log "deferred: gsettings is unavailable"
    return 0
  }
  gsettings writable org.gnome.desktop.interface color-scheme >/dev/null 2>&1 || {
    log "deferred: OS color-scheme setting is unavailable"
    return 0
  }

  # All remaining flavors (aws/azure/gcp/oci) are dark palettes.
  local scheme="prefer-dark"
  gsettings set org.gnome.desktop.interface color-scheme "$scheme" >/dev/null
  log "set color scheme: $scheme"
}

main "$@"
