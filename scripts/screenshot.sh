#!/usr/bin/env bash
#
# screenshot.sh — grim + slurp screenshot helper for Sway/Wayland.
# Saves to ~/Pictures/Screenshots and copies the result to the clipboard.
#
# Usage:
#   screenshot.sh full     # capture everything
#   screenshot.sh region   # interactively select an area
#   screenshot.sh window   # capture the currently focused window
#
set -euo pipefail

MODE="${1:-region}"
DIR="$HOME/Pictures/Screenshots"
FILE="$DIR/$(date +%Y-%m-%d_%H-%M-%S).png"

mkdir -p "$DIR"

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send "Screenshot" "$1" || true
}

case "$MODE" in
  full)
    grim "$FILE"
    ;;
  region)
    GEOM="$(slurp)" || { notify "Cancelled"; exit 0; }
    grim -g "$GEOM" "$FILE"
    ;;
  window)
    GEOM="$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')"
    if [ -z "$GEOM" ]; then
      notify "No focused window found"
      exit 1
    fi
    grim -g "$GEOM" "$FILE"
    ;;
  *)
    echo "Usage: $0 {full|region|window}" >&2
    exit 1
    ;;
esac

wl-copy < "$FILE"
notify "Saved to $FILE (copied to clipboard)"
