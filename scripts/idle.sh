#!/usr/bin/env bash
#
# idle.sh — swayidle daemon: auto-lock, screen off/on, suspend, and
# lock-before-sleep. Meant to be launched once per session via `exec` in the
# sway config.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK_CMD="$SCRIPT_DIR/lock.sh"

exec swayidle -w \
  timeout 300 "$LOCK_CMD" \
  timeout 600 'swaymsg "output * dpms off"' \
       resume 'swaymsg "output * dpms on"' \
  timeout 900 'systemctl suspend' \
  before-sleep "$LOCK_CMD"
