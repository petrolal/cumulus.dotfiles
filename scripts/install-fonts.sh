#!/usr/bin/env bash
#
# install-fonts.sh — install the JetBrainsMono Nerd Font used across this
# repo's kitty/waybar/wofi/sway configs (they all hardcode
# "JetBrainsMono Nerd Font" as font-family, so icons/glyphs render as boxes
# without it).
#
# Extracted into its own script (rather than living only inside
# install-zsh.sh) because install.sh runs it unconditionally for every
# install — the symlinked configs need this font regardless of whether you
# also want zsh/oh-my-zsh set up.
#
# Usage:
#   ./install-fonts.sh            # install if missing
#   ./install-fonts.sh --dry-run  # preview commands, change nothing
#
set -euo pipefail

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h|--help) grep '^#' "$0" | sed 's/^#//'; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

log() { printf '\033[1;34m[fonts]\033[0m %s\n' "$*"; }
run() { if $DRY_RUN; then echo "+ $*"; else eval "$@"; fi }

NERD_FONT_NAME="JetBrainsMono"
NERD_FONT_VERSION="v3.2.1"
FONTS_DIR="$HOME/.local/share/fonts"

install_nerd_font() {
  local match_count
  match_count="$(fc-list 2>/dev/null | grep -ci "JetBrainsMono Nerd Font" || true)"
  if [ "${match_count:-0}" -gt 0 ]; then
    log "OK (already installed): $NERD_FONT_NAME Nerd Font"
    return
  fi
  log "Installing $NERD_FONT_NAME Nerd Font $NERD_FONT_VERSION..."
  run "mkdir -p '$FONTS_DIR'"
  run "curl -fLo /tmp/${NERD_FONT_NAME}.zip \
    'https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/${NERD_FONT_NAME}.zip'"
  run "unzip -o -q /tmp/${NERD_FONT_NAME}.zip -d '$FONTS_DIR' '*.ttf'"
  run "rm -f /tmp/${NERD_FONT_NAME}.zip"
  run "fc-cache -f '$FONTS_DIR'"
  log "Installed. kitty/waybar/wofi/sway in this repo already default to '$NERD_FONT_NAME Nerd Font'."
}

main() {
  $DRY_RUN && log "DRY RUN — no changes will be made"
  install_nerd_font
}

main "$@"
