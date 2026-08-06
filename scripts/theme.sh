#!/usr/bin/env bash
#
# theme.sh — select a desktop flavor + background mode for this whole
# desktop (sway, waybar, wofi, kitty) and apply it live.
#
# Concepts:
#   - Flavor: one of the palettes in themes/palettes/*.sh, including the four
#       Catppuccin flavors and the AWS/Azure/GCP/OCI cloud themes.
#   - Background mode:
#       flat      — solid color using the flavor's "base" swatch (default,
#                   no wallpaper image at all).
#       wallpaper — a single static image from themes/wallpapers/.
#       rotate    — cycle through every image in themes/wallpapers/ on a
#                   timer (systemd --user timer), same flavor's colors used
#                   throughout regardless of which image is showing.
#
# State is persisted in ~/.config/cumulus/theme/state so it re-applies the
# same way after reboot/login (wired into sway's exec_always) and after
# ./install.sh (wired automatically).
#
# Usage:
#   ./theme.sh set <flavor>                              # flat color (default mode)
#   ./theme.sh set <flavor> --theme-default              # use the flavor's tracked wallpaper
#   ./theme.sh set <flavor> --preserve-background        # keep current wallpaper/rotation mode
#   ./theme.sh set <flavor> --wallpaper <path|filename>  # static wallpaper
#   ./theme.sh set <flavor> --rotate [--interval 30m]    # rotate images in themes/wallpapers/
#   ./theme.sh set <flavor> --flat                       # force flat color mode
#   ./theme.sh apply                                     # re-apply the saved state (no changes)
#   ./theme.sh next                                      # advance to the next wallpaper now (rotate mode)
#   ./theme.sh list                                      # list available flavors + wallpapers
#   ./theme.sh current                                   # show the active flavor/mode
#
set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(cd "$(dirname "$SELF")/.." && pwd)"
PALETTES_DIR="$DOTFILES_DIR/themes/palettes"
WALLPAPERS_DIR="$DOTFILES_DIR/themes/wallpapers"
STATE_DIR="$HOME/.config/cumulus/theme"
STATE_FILE="$STATE_DIR/state"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

log() { printf '\033[1;35m[theme]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[theme] error:\033[0m %s\n' "$*" >&2; exit 1; }

write_state() {
  local flavor="$1" mode="$2" wallpaper="$3" wallpaper_source="$4"
  local interval="$5" nvim_colorscheme="$6" tmp_state
  mkdir -p "$STATE_DIR"
  tmp_state="$(mktemp "$STATE_DIR/state.XXXXXX")"
  {
    echo "FLAVOR=$flavor"
    echo "MODE=$mode"
    echo "WALLPAPER=$wallpaper"
    echo "WALLPAPER_SOURCE=$wallpaper_source"
    echo "INTERVAL=$interval"
    echo "NVIM_COLORSCHEME=$nvim_colorscheme"
  } > "$tmp_state"
  chmod 600 "$tmp_state"
  mv -f "$tmp_state" "$STATE_FILE"
}

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

valid_flavors() { basename -s .sh -a "$PALETTES_DIR"/*.sh; }

is_valid_flavor() {
  local f="$1"
  [ -f "$PALETTES_DIR/$f.sh" ]
}

default_wallpaper() {
  local flavor="$1" candidate="$WALLPAPERS_DIR/$1.svg"
  [ -f "$candidate" ] && printf '%s\n' "$candidate"
}

validate_palette() {
  local flavor="$1" var
  for var in THEME_NAME THEME_LABEL NVIM_COLORSCHEME; do
    [ -n "${!var:-}" ] || die "palette '$flavor' is missing metadata: $var"
  done
  [[ "$THEME_NAME" = "$flavor" ]] ||
    die "palette '$flavor' has mismatched THEME_NAME: $THEME_NAME"
  [[ "$NVIM_COLORSCHEME" =~ ^[A-Za-z0-9_.-]+$ ]] ||
    die "palette '$flavor' has invalid NVIM_COLORSCHEME: $NVIM_COLORSCHEME"
  for var in BASE MANTLE CRUST TEXT SUBTEXT1 SUBTEXT0 SURFACE0 SURFACE1 \
             SURFACE2 OVERLAY0 BLUE LAVENDER SAPPHIRE SKY TEAL GREEN YELLOW \
             PEACH MAROON RED MAUVE PINK FLAMINGO ROSEWATER; do
    [ -n "${!var:-}" ] || die "palette '$flavor' is missing required variable: $var"
    [[ "${!var}" =~ ^#[[:xdigit:]]{6}$ ]] ||
      die "palette '$flavor' has invalid hex color for $var: ${!var}"
  done
}

validate_templates() {
  local template placeholder
  for template in "$DOTFILES_DIR/config/waybar/style.css.tmpl" \
                  "$DOTFILES_DIR/config/wofi/style.css.tmpl"; do
    [ -f "$template" ] || die "missing theme template: $template"
    for placeholder in @@BASE@@ @@TEXT@@ @@SURFACE0@@ @@BLUE@@; do
      grep -Fq "$placeholder" "$template" ||
        die "theme template is missing placeholder $placeholder: $template"
    done
  done
}

normalize_mode() {
  case "${1:-flat}" in
    flat|wallpaper|rotate) printf '%s\n' "$1" ;;
    *) printf 'flat\n' ;;
  esac
}

validate_interval() {
  local interval="$1"
  [[ "$interval" =~ ^[1-9][0-9]*(ms|us|s|m|h|d|w)$ ]] ||
    die "invalid rotation interval: $interval (use values such as 30m or 1h)"
}

# ── Generate colors.conf/colors.css for each app from a palette file ────────
generate_configs() {
  local flavor="$1" mode="$2" wallpaper="${3:-}"
  local render_dir
  unset THEME_NAME THEME_LABEL NVIM_COLORSCHEME
  # shellcheck disable=SC1090
  source "$PALETTES_DIR/$flavor.sh"
  validate_palette "$flavor"
  validate_templates

  mkdir -p "$STATE_DIR"
  render_dir="$(mktemp -d "$STATE_DIR/render.XXXXXX")"

  # sway: wallpaper exec + client colors
  {
    echo "# Generated by scripts/theme.sh — flavor=$flavor mode=$mode. Do not edit by hand."
    if [ "$mode" = "flat" ]; then
      echo "exec_always swaybg -c \"$BASE\""
    else
      echo "exec_always swaybg -i \"$wallpaper\" -m fill"
    fi
    echo
    echo "# class                 border      bg          text        indicator   child_border"
    echo "client.focused          $BLUE       $BASE       $TEXT       $BLUE       $BLUE"
    echo "client.focused_inactive $SURFACE1   $BASE       $TEXT       $SURFACE1   $SURFACE1"
    echo "client.unfocused        $SURFACE0   $BASE       $SUBTEXT0   $SURFACE0   $SURFACE0"
    echo "client.urgent           $RED        $BASE       $RED        $RED        $RED"
  } > "$render_dir/sway.colors.conf"

  # waybar: render style.css from style.css.tmpl (@@PLACEHOLDER@@ substitution).
  # Rendered directly rather than via GTK CSS @import, since @import in GTK
  # CSS resolves relative to the consuming app's process CWD, not the
  # including file's location — fragile depending on how sway launches it.
  sed \
    -e "s/@@BASE@@/$BASE/g" -e "s/@@TEXT@@/$TEXT/g" -e "s/@@SUBTEXT0@@/$SUBTEXT0/g" \
    -e "s/@@SURFACE0@@/$SURFACE0/g" -e "s/@@BLUE@@/$BLUE/g" -e "s/@@RED@@/$RED/g" \
    -e "s/@@YELLOW@@/$YELLOW/g" \
    "$DOTFILES_DIR/config/waybar/style.css.tmpl" > "$render_dir/waybar.style.css"

  # wofi: same template-rendering approach.
  sed \
    -e "s/@@BASE@@/$BASE/g" -e "s/@@TEXT@@/$TEXT/g" \
    -e "s/@@SURFACE0@@/$SURFACE0/g" -e "s/@@BLUE@@/$BLUE/g" \
    "$DOTFILES_DIR/config/wofi/style.css.tmpl" > "$render_dir/wofi.style.css"

  # kitty: native kitty.conf syntax
  {
    echo "# Generated by scripts/theme.sh — flavor=$flavor. Do not edit by hand."
    echo "foreground $TEXT"
    echo "background $BASE"
    echo "selection_foreground $BASE"
    echo "selection_background $ROSEWATER"
    echo "cursor $ROSEWATER"
    echo "cursor_text_color $BASE"
    echo "url_color $ROSEWATER"
    echo "active_border_color $LAVENDER"
    echo "inactive_border_color $OVERLAY0"
    echo "bell_border_color $YELLOW"
    echo "wayland_titlebar_color background"
    echo "active_tab_background $BASE"
    echo "active_tab_foreground $TEXT"
    echo "inactive_tab_background $MANTLE"
    echo "inactive_tab_foreground $SUBTEXT0"
    echo "tab_bar_background $CRUST"
    echo "color0 $SURFACE1"
    echo "color8 $SURFACE2"
    echo "color1 $RED"
    echo "color9 $RED"
    echo "color2 $GREEN"
    echo "color10 $GREEN"
    echo "color3 $YELLOW"
    echo "color11 $YELLOW"
    echo "color4 $BLUE"
    echo "color12 $BLUE"
    echo "color5 $PINK"
    echo "color13 $PINK"
    echo "color6 $TEAL"
    echo "color14 $TEAL"
    echo "color7 $SUBTEXT1"
    echo "color15 $SUBTEXT0"
  } > "$render_dir/kitty.colors.conf"

  mv -f "$render_dir/sway.colors.conf" "$DOTFILES_DIR/config/sway/colors.conf"
  mv -f "$render_dir/waybar.style.css" "$DOTFILES_DIR/config/waybar/style.css"
  mv -f "$render_dir/wofi.style.css" "$DOTFILES_DIR/config/wofi/style.css"
  mv -f "$render_dir/kitty.colors.conf" "$DOTFILES_DIR/config/kitty/colors.conf"
  rmdir "$render_dir"
}

# ── Reload the running apps to pick up the new colors ───────────────────────
reload_apps() {
  if [ -x "$DOTFILES_DIR/scripts/runtime-refresh.sh" ]; then
    "$DOTFILES_DIR/scripts/runtime-refresh.sh"
  else
    log "Runtime refresh coordinator unavailable; colors apply on next launch."
  fi
}

# ── systemd --user timer for rotate mode ────────────────────────────────────
write_rotate_units() {
  local interval="$1"
  mkdir -p "$SYSTEMD_USER_DIR"

  cat > "$SYSTEMD_USER_DIR/cumulus-wallpaper-rotate.service" <<EOF
[Unit]
Description=cumulus.dotfiles wallpaper rotation (single tick)

[Service]
Type=oneshot
ExecStart=$DOTFILES_DIR/scripts/theme.sh next
EOF

  cat > "$SYSTEMD_USER_DIR/cumulus-wallpaper-rotate.timer" <<EOF
[Unit]
Description=cumulus.dotfiles wallpaper rotation timer

[Timer]
OnBootSec=$interval
OnUnitActiveSec=$interval
Persistent=true

[Install]
WantedBy=timers.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable --now cumulus-wallpaper-rotate.timer
  log "Enabled rotation timer: every $interval (systemctl --user status cumulus-wallpaper-rotate.timer)"
}

disable_rotate_units() {
  if systemctl --user list-unit-files 2>/dev/null | grep -q cumulus-wallpaper-rotate.timer; then
    systemctl --user disable --now cumulus-wallpaper-rotate.timer >/dev/null 2>&1 || true
    log "Disabled rotation timer."
  fi
}

# ── Subcommands ──────────────────────────────────────────────────────────────
cmd_set() {
  local flavor="${1:-}"; shift || true
  [ -n "$flavor" ] || die "usage: theme.sh set <flavor> [--wallpaper <path>|--rotate [--interval N]|--flat]"
  is_valid_flavor "$flavor" || die "unknown flavor '$flavor' — choices: $(valid_flavors | tr '\n' ' ')"

  local mode="flat" wallpaper="" interval="30m" wallpaper_source="flat"
  local preserve_background=false mode_explicit=false wallpaper_explicit=false
  local theme_default_explicit=false
  while [ $# -gt 0 ]; do
    case "$1" in
      --wallpaper) mode="wallpaper"; mode_explicit=true; wallpaper_explicit=true; wallpaper="$2"; shift 2 ;;
      --theme-default) mode="wallpaper"; wallpaper_source="theme-default"; theme_default_explicit=true; mode_explicit=true; shift ;;
      --rotate) mode="rotate"; mode_explicit=true; shift ;;
      --interval) interval="$2"; shift 2 ;;
      --flat) mode="flat"; mode_explicit=true; shift ;;
      --preserve-background) preserve_background=true; shift ;;
      *) die "unknown option: $1" ;;
    esac
  done

  if $preserve_background && ! $mode_explicit && [ -f "$STATE_FILE" ]; then
    load_state
    mode="${MODE:-flat}"
    wallpaper="${WALLPAPER:-}"
    interval="${INTERVAL:-30m}"
    wallpaper_source="${WALLPAPER_SOURCE:-}"
  fi

  mode="$(normalize_mode "$mode")"
  validate_interval "$interval"

  if [ "$mode" = "flat" ]; then
    wallpaper=""
    wallpaper_source="flat"
  elif [ "$mode" = "rotate" ]; then
    wallpaper_source="rotate"
  fi

  # A theme-default wallpaper follows the selected flavor. A user wallpaper
  # remains untouched; if it disappeared, fall back to the new default.
  if [ "$mode" = "wallpaper" ] && [ "$wallpaper_source" = "theme-default" ]; then
    wallpaper="$(default_wallpaper "$flavor")"
    [ -n "$wallpaper" ] || { mode="flat"; wallpaper=""; wallpaper_source="flat"; }
  elif [ "$mode" = "wallpaper" ]; then
    if ! $wallpaper_explicit && [ -n "$wallpaper" ] && [ ! -f "$wallpaper" ] && [ -n "$(default_wallpaper "$flavor")" ]; then
      wallpaper="$(default_wallpaper "$flavor")"
      wallpaper_source="theme-default"
    elif ! $wallpaper_explicit && [ -n "$wallpaper" ] && [ ! -f "$wallpaper" ]; then
      mode="flat"
      wallpaper=""
      wallpaper_source="flat"
    fi
    [ "$mode" != "wallpaper" ] || [ -n "$wallpaper" ] || die "wallpaper path is empty"
  fi

  if [ "$mode" = "wallpaper" ]; then
    [ -n "$wallpaper" ] || die "wallpaper path is empty"
    # Allow bare filenames relative to themes/wallpapers/
    if [ ! -f "$wallpaper" ] && [ -f "$WALLPAPERS_DIR/$wallpaper" ]; then
      wallpaper="$WALLPAPERS_DIR/$wallpaper"
    fi
    [ -f "$wallpaper" ] || die "wallpaper not found: $wallpaper (put images in themes/wallpapers/ or pass a full path)"
    wallpaper="$(cd "$(dirname "$wallpaper")" && pwd)/$(basename "$wallpaper")"
    if $theme_default_explicit; then
      wallpaper_source="theme-default"
    elif $wallpaper_explicit || [ "$wallpaper_source" = user ]; then
      wallpaper_source="user"
    elif [ "$wallpaper_source" = theme-default ]; then
      wallpaper_source="theme-default"
    else
      case "$wallpaper" in
        "$WALLPAPERS_DIR"/*.svg) wallpaper_source="theme-default" ;;
        *) wallpaper_source="user" ;;
      esac
    fi
  fi

  if [ "$mode" = "rotate" ]; then
    shopt -s nullglob
    local images=("$WALLPAPERS_DIR"/*.{jpg,jpeg,png,webp})
    shopt -u nullglob
    [ "${#images[@]}" -gt 0 ] || die "no images found in $WALLPAPERS_DIR — add some first"
    wallpaper="${images[0]}"
  fi

  # Load and validate metadata before persisting shared state.
  unset THEME_NAME THEME_LABEL NVIM_COLORSCHEME
  # shellcheck disable=SC1090
  source "$PALETTES_DIR/$flavor.sh"
  validate_palette "$flavor"

  generate_configs "$flavor" "$mode" "$wallpaper"
  write_state "$flavor" "$mode" "${wallpaper:-}" "$wallpaper_source" "$interval" "${NVIM_COLORSCHEME:-}"

  if [ "$mode" = "rotate" ]; then
    write_rotate_units "$interval"
  else
    disable_rotate_units
  fi

  reload_apps
  log "Theme set: $flavor / $mode${wallpaper:+ ($(basename "$wallpaper"))}"
}

cmd_apply() {
  [ -f "$STATE_FILE" ] || { log "No saved theme state — applying default (mocha / flat)."; cmd_set mocha; return; }
  load_state
  local fallback
  is_valid_flavor "${FLAVOR:-}" || die "invalid saved flavor: ${FLAVOR:-<missing>}"
  MODE="$(normalize_mode "${MODE:-flat}")"
  INTERVAL="${INTERVAL:-30m}"
  validate_interval "$INTERVAL"
  case "$MODE" in
    flat) WALLPAPER=""; WALLPAPER_SOURCE="flat" ;;
    rotate) WALLPAPER_SOURCE="rotate" ;;
    wallpaper)
      if [ -z "${WALLPAPER_SOURCE:-}" ]; then
        case "${WALLPAPER:-}" in
          "$WALLPAPERS_DIR"/*.svg) WALLPAPER_SOURCE="theme-default" ;;
          *) WALLPAPER_SOURCE="user" ;;
        esac
      fi
      ;;
  esac
  if [ "$MODE" = "wallpaper" ] && [ ! -f "${WALLPAPER:-}" ]; then
    fallback="$(default_wallpaper "$FLAVOR")"
    if [ -n "$fallback" ]; then
      WALLPAPER="$fallback"
      WALLPAPER_SOURCE="theme-default"
    else
      MODE="flat"
      WALLPAPER=""
      WALLPAPER_SOURCE="flat"
    fi
  elif [ "$MODE" = "rotate" ]; then
    shopt -s nullglob
    local images=("$WALLPAPERS_DIR"/*.{jpg,jpeg,png,webp})
    shopt -u nullglob
    if [ "${#images[@]}" -eq 0 ]; then
      MODE="flat"
      WALLPAPER=""
      WALLPAPER_SOURCE="flat"
    elif [ ! -f "${WALLPAPER:-}" ]; then
      WALLPAPER="${images[0]}"
      WALLPAPER_SOURCE="rotate"
    fi
  fi
  generate_configs "$FLAVOR" "$MODE" "${WALLPAPER:-}"
  write_state "$FLAVOR" "$MODE" "${WALLPAPER:-}" "${WALLPAPER_SOURCE:-}" \
    "$INTERVAL" "${NVIM_COLORSCHEME:-}"
  [ "$MODE" = "rotate" ] && write_rotate_units "$INTERVAL"
  reload_apps
  log "Re-applied saved theme: $FLAVOR / $MODE"
}

cmd_next() {
  [ -f "$STATE_FILE" ] || die "no theme set yet — run 'theme.sh set <flavor> --rotate' first"
  load_state
  is_valid_flavor "${FLAVOR:-}" || die "invalid saved flavor: ${FLAVOR:-<missing>}"
  [ "$MODE" = "rotate" ] || die "current mode is '$MODE', not rotate — nothing to advance"
  validate_interval "${INTERVAL:-30m}"

  shopt -s nullglob
  local images=("$WALLPAPERS_DIR"/*.{jpg,jpeg,png,webp})
  shopt -u nullglob
  [ "${#images[@]}" -gt 0 ] || die "no images found in $WALLPAPERS_DIR"

  local current="$WALLPAPER" next_idx=0 i
  for i in "${!images[@]}"; do
    if [ "${images[$i]}" = "$current" ]; then
      next_idx=$(( (i + 1) % ${#images[@]} ))
      break
    fi
  done
  local next_wallpaper="${images[$next_idx]}"

  write_state "$FLAVOR" rotate "$next_wallpaper" rotate \
    "${INTERVAL:-30m}" "${NVIM_COLORSCHEME:-}"
  generate_configs "$FLAVOR" "rotate" "$next_wallpaper"
  reload_apps
  log "Advanced wallpaper -> $(basename "$next_wallpaper")"
}

cmd_list() {
  echo "Flavors:"
  local f
  for f in $(valid_flavors); do
    unset THEME_NAME THEME_LABEL NVIM_COLORSCHEME
    # shellcheck disable=SC1090
    source "$PALETTES_DIR/$f.sh"
    printf '  %-10s %s\n' "$f" "$THEME_LABEL"
  done
  echo
  echo "Wallpapers ($WALLPAPERS_DIR):"
  shopt -s nullglob
  local images=("$WALLPAPERS_DIR"/*.{jpg,jpeg,png,webp})
  shopt -u nullglob
  if [ "${#images[@]}" -eq 0 ]; then
    echo "  (none — drop image files in themes/wallpapers/ to use --wallpaper/--rotate)"
  else
    printf '  %s\n' "${images[@]##*/}"
  fi
}

cmd_current() {
  if [ -f "$STATE_FILE" ]; then
    load_state
    echo "Flavor:  $FLAVOR"
    echo "Mode:    $MODE"
    echo "Source:  ${WALLPAPER_SOURCE:-legacy}"
    [ -n "${WALLPAPER:-}" ] && echo "Image:   $(basename "$WALLPAPER")"
    if [ "$MODE" = "rotate" ]; then
      echo "Interval: ${INTERVAL:-30m}"
    fi
  else
    echo "No theme set yet (default is mocha / flat)."
  fi
}

main() {
  local sub="${1:-}"; shift || true
  case "$sub" in
    set) cmd_set "$@" ;;
    apply) cmd_apply ;;
    next) cmd_next ;;
    list) cmd_list ;;
    current) cmd_current ;;
    -h|--help|"") grep '^#' "$0" | sed 's/^#//'; exit 0 ;;
    *) die "unknown subcommand '$sub' (set/apply/next/list/current)" ;;
  esac
}

main "$@"
