#!/usr/bin/env bash
#
# rgb-theme.sh — synchronize hardware RGB lighting (OpenRGB, asusctl, liquidctl)
# with the active cumulus.dotfiles theme color.
#
# Usage:
#   ./rgb-theme.sh [flavor]
#
set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(cd "$(dirname "$SELF")/.." && pwd)"
STATE_FILE="$HOME/.config/cumulus/theme/state"
PALETTES_DIR="$DOTFILES_DIR/themes/palettes"

FLAVOR="${1:-}"
if [ -z "$FLAVOR" ] && [ -f "$STATE_FILE" ]; then
  # shellcheck disable=SC1090
  . "$STATE_FILE"
fi
FLAVOR="${FLAVOR:-oci}"

PALETTE="$PALETTES_DIR/$FLAVOR.sh"
[ -f "$PALETTE" ] || PALETTE="$PALETTES_DIR/oci.sh"
# shellcheck disable=SC1090
. "$PALETTE"

# Strip leading '#' from hex color
RAW_COLOR="${BLUE:-#0073bb}"
HEX_COLOR="${RAW_COLOR#\#}"

UPDATED=false

# 1. OpenRGB (Motherboard, RAM, GPU, Mouse, USB Keyboards, Addressable RGB)
if command -v openrgb >/dev/null 2>&1; then
  if openrgb --color "$HEX_COLOR" --mode static >/dev/null 2>&1 || \
     openrgb --color "$HEX_COLOR" >/dev/null 2>&1; then
    UPDATED=true
  fi
fi

# 2. asusctl (ASUS ROG/TUF Laptop Keyboard RGB)
if command -v asusctl >/dev/null 2>&1; then
  if asusctl led-mode static -c "$HEX_COLOR" >/dev/null 2>&1; then
    UPDATED=true
  fi
fi

# 3. liquidctl (Liquid Coolers & Fan Controllers)
if command -v liquidctl >/dev/null 2>&1; then
  if liquidctl set ring color fixed "$HEX_COLOR" >/dev/null 2>&1 || \
     liquidctl set sync color fixed "$HEX_COLOR" >/dev/null 2>&1; then
    UPDATED=true
  fi
fi

if $UPDATED; then
  exit 0
else
  exit 1
fi
