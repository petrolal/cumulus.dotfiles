#!/usr/bin/env bash
#
# lock.sh — swaylock wrapper with styling that follows the active
# dotfiles theme (see scripts/theme.sh). Bind this to Mod+Escape (or
# call from idle.sh) instead of raw swaylock, so the look stays defined
# in one place and updates automatically when you switch flavors.
#
set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(cd "$(dirname "$SELF")/.." && pwd)"
STATE_FILE="$HOME/.config/dotfiles/theme/state"

FLAVOR="mocha"
if [ -f "$STATE_FILE" ]; then
  # shellcheck disable=SC1090
  . "$STATE_FILE"
  FLAVOR="${FLAVOR:-mocha}"
fi

PALETTE="$DOTFILES_DIR/themes/palettes/$FLAVOR.sh"
[ -f "$PALETTE" ] || PALETTE="$DOTFILES_DIR/themes/palettes/mocha.sh"
# shellcheck disable=SC1090
. "$PALETTE"

# swaylock wants colors without the leading '#'.
strip_hash() { printf '%s' "${1#\#}"; }

BASE_C="$(strip_hash "$BASE")"
BLUE_C="$(strip_hash "$BLUE")"
TEXT_C="$(strip_hash "$TEXT")"
GREEN_C="$(strip_hash "$GREEN")"

exec swaylock \
  --color "$BASE_C" \
  --inside-color "$BASE_C" \
  --ring-color "$BLUE_C" \
  --line-color "$BASE_C" \
  --text-color "$TEXT_C" \
  --inside-ver-color "$BLUE_C" \
  --ring-ver-color "$BLUE_C" \
  --key-hl-color "$GREEN_C" \
  --separator-color "$BASE_C" \
  --font "JetBrainsMono Nerd Font" \
  --indicator-radius 100 \
  --indicator-thickness 10
