#!/usr/bin/env bash
#
# theme-picker.sh — wofi GUI front-end for scripts/theme.sh.
#
# Walks you through: flavor -> background mode -> (wallpaper file | rotate
# interval), then calls `theme.sh set ...` with the result. Purely a UI
# layer over the existing CLI — no logic here duplicates what theme.sh
# already does (flavor/wallpaper validation, config generation, sway
# reload, state persistence all still happen there).
#
# Bound to $mod+Shift+t in config/sway/config. Can also be run by hand:
#   ~/cumulus.dotfiles/config/sway/scripts/theme-picker.sh
#
set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(cd "$(dirname "$SELF")/../../.." && pwd)"
THEME_SH="$DOTFILES_DIR/scripts/theme.sh"
PALETTES_DIR="$DOTFILES_DIR/themes/palettes"
WALLPAPERS_DIR="$DOTFILES_DIR/themes/wallpapers"
STATE_FILE="$HOME/.config/cumulus/theme/state"

current_flavor=""
current_source="flat"
if [ -f "$STATE_FILE" ]; then
  # shellcheck disable=SC1090
  source "$STATE_FILE"
  current_flavor="${FLAVOR:-}"
  current_source="${WALLPAPER_SOURCE:-legacy}"
fi

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send "Theme" "$1" || true
}

pick() {
  # pick <prompt> <<< "newline-separated options"
  wofi --show dmenu --prompt "$1" --width 500 --height 400 --lines 8 --insensitive
}

# ── 1. Flavor ────────────────────────────────────────────────────────────
flavor_lines=""
for f in "$PALETTES_DIR"/*.sh; do
  name="$(basename -s .sh "$f")"
  # shellcheck disable=SC1090
  label="$(source "$f"; echo "$THEME_LABEL")"
  marker=""
  [ "$name" = "$current_flavor" ] && marker="✓ "
  flavor_lines+="$marker$name — $label"$'\n'
done

flavor_choice="$(printf '%s' "$flavor_lines" | pick "Theme flavor")"
[ -n "$flavor_choice" ] || exit 0
flavor="${flavor_choice%% —*}"
flavor="${flavor#✓ }"

if [ "$current_source" = "user" ]; then
  notify "Custom wallpaper will be preserved unless you choose the theme default or flat color."
fi

# ── 2. Background mode ───────────────────────────────────────────────────
mode_choice="$(printf 'Flat color\nTheme default wallpaper\nCustom wallpaper (pick an image)\nRotate wallpapers (timer)' | pick "Background mode")"
[ -n "$mode_choice" ] || exit 0

case "$mode_choice" in
  "Flat color")
    "$THEME_SH" set "$flavor" --flat
    notify "Set to $flavor / flat color"
    ;;

  "Theme default wallpaper")
    "$THEME_SH" set "$flavor" --theme-default
    notify "Set to $flavor / tracked theme wallpaper"
    ;;

  "Custom wallpaper"*)
    shopt -s nullglob
    images=("$WALLPAPERS_DIR"/*.{jpg,jpeg,png,webp})
    shopt -u nullglob
    if [ "${#images[@]}" -eq 0 ]; then
      notify "No wallpapers found in $WALLPAPERS_DIR — add images first"
      exit 1
    fi
    wallpaper_choice="$(printf '%s\n' "${images[@]##*/}" | pick "Wallpaper")"
    [ -n "$wallpaper_choice" ] || exit 0
    "$THEME_SH" set "$flavor" --wallpaper "$wallpaper_choice"
    notify "Set to $flavor / $wallpaper_choice"
    ;;

  "Rotate"*)
    interval="$(printf '30m\n15m\n1h\n2h' | pick "Rotate interval (type a custom value, e.g. 45m)")"
    [ -n "$interval" ] || exit 0
    "$THEME_SH" set "$flavor" --rotate --interval "$interval"
    notify "Set to $flavor / rotate every $interval"
    ;;
esac
