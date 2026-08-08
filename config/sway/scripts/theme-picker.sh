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
current_mode="flat"
if [ -f "$STATE_FILE" ]; then
  load_state() {
    local key value
    unset FLAVOR MODE WALLPAPER WALLPAPER_SOURCE INTERVAL NVIM_COLORSCHEME
    while IFS='=' read -r key value || [ -n "$key" ]; do
      case "$key" in
        FLAVOR|MODE|WALLPAPER|WALLPAPER_SOURCE|INTERVAL|NVIM_COLORSCHEME)
          printf -v "$key" '%s' "$value"
          ;;
      esac
    done < "$STATE_FILE"
  }
  load_state
  current_flavor="${FLAVOR:-}"
  current_mode="${MODE:-flat}"
  current_source="${WALLPAPER_SOURCE:-legacy}"
fi

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send "Theme" "$1" || true
}

source_label() {
  case "$1" in
    user) printf 'custom wallpaper (preserved)\n' ;;
    theme-default) printf 'theme default wallpaper\n' ;;
    rotate) printf 'rotating wallpapers\n' ;;
    flat) printf 'flat color\n' ;;
    *) printf 'legacy/unknown wallpaper source\n' ;;
  esac
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

current_source_label="$(source_label "$current_source")"
flavor_choice="$(printf '%s' "$flavor_lines" | pick \
  "Theme flavor (current: ${current_flavor:-none}; wallpaper: $current_source_label)")"
[ -n "$flavor_choice" ] || exit 0
flavor="${flavor_choice%% —*}"
flavor="${flavor#✓ }"

if [ "$current_source" = "user" ]; then
  notify "Custom wallpaper will be preserved unless you choose a different background mode."
fi

# ── 2. Background mode ───────────────────────────────────────────────────
current_mode_label="$current_mode"
case "$current_mode" in
  flat) current_mode_label=flat ;;
  rotate) current_mode_label=rotate ;;
  wallpaper)
    case "$current_source" in
      user|theme-default) current_mode_label="$current_source" ;;
      *) current_mode_label=legacy ;;
    esac
    ;;
  *) current_mode_label=legacy ;;
esac
current_mode_label="$(source_label "$current_mode_label")"
mode_choice="$(printf 'Plain color\nRotate wallpapers\nSelect wallpaper' | pick \
  "Background mode (current: $current_mode_label)")"
[ -n "$mode_choice" ] || exit 0

get_flavor_images() {
  local target_flavor="$1"
  local f file
  local -a out_images=()
  shopt -s nullglob
  for file in "$WALLPAPERS_DIR"/*; do
    [ -f "$file" ] || continue
    case "$file" in
      *.jpg|*.jpeg|*.png|*.webp|*.svg) ;;
      *) continue ;;
    esac
    f="$(basename "$file")"
    if [[ "$f" =~ ^${target_flavor}(\.|_|-).* ]]; then
      out_images+=("$file")
    fi
  done
  if [ "${#out_images[@]}" -eq 0 ]; then
    for file in "$WALLPAPERS_DIR"/*; do
      [ -f "$file" ] || continue
      case "$file" in
        *.jpg|*.jpeg|*.png|*.webp|*.svg) out_images+=("$file") ;;
      esac
    done
  fi
  shopt -u nullglob
  printf '%s\n' "${out_images[@]}"
}

case "$mode_choice" in
  "Plain color"*)
    "$THEME_SH" set "$flavor" --flat
    notify "Set to $flavor / plain color"
    ;;

  "Rotate wallpapers"*)
    mapfile -t images < <(get_flavor_images "$flavor")
    if [ "${#images[@]}" -eq 0 ] || [ -z "${images[0]:-}" ]; then
      notify "No wallpapers found in $WALLPAPERS_DIR — add images before enabling rotation"
      exit 1
    fi
    interval="$(printf '30m\n15m\n1h\n2h' | pick "Rotate interval (type a custom value, e.g. 45m)")"
    [ -n "$interval" ] || exit 0
    "$THEME_SH" set "$flavor" --rotate --interval "$interval"
    notify "Set to $flavor / rotate every $interval"
    ;;

  "Select wallpaper"*)
    mapfile -t images < <(get_flavor_images "$flavor")
    if [ "${#images[@]}" -eq 0 ] || [ -z "${images[0]:-}" ]; then
      notify "No wallpapers found in $WALLPAPERS_DIR — add images first"
      exit 1
    fi
    wallpaper_choice="$(printf '%s\n' "${images[@]##*/}" | pick "Select wallpaper for $flavor")"
    [ -n "$wallpaper_choice" ] || exit 0
    "$THEME_SH" set "$flavor" --wallpaper "$wallpaper_choice"
    notify "Set to $flavor / $wallpaper_choice"
    ;;
esac
