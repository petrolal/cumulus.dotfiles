#!/usr/bin/env bash
#
# Isolated tests for the Sway theme picker UI boundaries.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

assert() {
  if ! "$@"; then
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
  fi
}

make_fixture() {
  local name="$1"
  local fixture="$TMP_DIR/$name"
  cp -a "$REPO_ROOT" "$fixture"
  mkdir -p "$fixture/bin" "$fixture/home/.config/cumulus/theme"
  cat > "$fixture/bin/wofi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
call_file="${WOFI_CALLS:?}"
call=0
[ -f "$call_file" ] && read -r call < "$call_file"
call=$((call + 1))
printf '%s\n' "$call" > "$call_file"
cat > "${WOFI_MENUS:?}/$call"
prompt=""
while [ "$#" -gt 0 ]; do
  if [ "$1" = --prompt ]; then
    prompt="$2"
    break
  fi
  shift
done
printf '%s\n' "$prompt" >> "${WOFI_PROMPTS:?}"
sed -n "${call}p" "${WOFI_RESPONSES:?}"
EOF
  chmod +x "$fixture/bin/wofi"
  cat > "$fixture/bin/notify-send" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${NOTIFY_LOG:?}"
EOF
  chmod +x "$fixture/bin/notify-send"
  cat > "$fixture/scripts/theme.sh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${THEME_LOG:?}"
EOF
  chmod +x "$fixture/scripts/theme.sh"
  printf '%s\n' \
    'FLAVOR=aws' \
    'MODE=wallpaper' \
    'WALLPAPER=/tmp/personal.png' \
    'WALLPAPER_SOURCE=user' \
    'INTERVAL=30m' \
    'NVIM_COLORSCHEME=aws-theme' \
    > "$fixture/home/.config/cumulus/theme/state"
  printf 'custom wallpaper\n' > "$fixture/themes/wallpapers/custom.jpg"
  printf '%s\n' "$fixture"
}

fixture="$(make_fixture picker)"
export HOME="$fixture/home"
export PATH="$fixture/bin:$PATH"
export WOFI_CALLS="$TMP_DIR/wofi-calls"
export WOFI_MENUS="$TMP_DIR/wofi-menus"
export WOFI_PROMPTS="$TMP_DIR/wofi-prompts"
export WOFI_RESPONSES="$TMP_DIR/wofi-responses"
export NOTIFY_LOG="$TMP_DIR/notifications"
export THEME_LOG="$TMP_DIR/theme-calls"
mkdir -p "$WOFI_MENUS"

before="$(sha256sum "$HOME/.config/cumulus/theme/state")"
before_sway="$(sha256sum "$fixture/config/sway/colors.conf")"
before_waybar="$(sha256sum "$fixture/config/waybar/style.css")"
assert_unchanged() {
  assert test "$(sha256sum "$HOME/.config/cumulus/theme/state")" = "$before"
  assert test "$(sha256sum "$fixture/config/sway/colors.conf")" = "$before_sway"
  assert test "$(sha256sum "$fixture/config/waybar/style.css")" = "$before_waybar"
}
printf '\n' > "$WOFI_RESPONSES"
env -u THEME_LOG "$fixture/config/sway/scripts/theme-picker.sh" >/dev/null
assert_unchanged
assert test ! -e "$THEME_LOG"

rm -f "$WOFI_CALLS" "$WOFI_PROMPTS" "$NOTIFY_LOG" "$THEME_LOG"
printf '%s\n\n' '✓ aws — AWS Cloud (dark)' > "$WOFI_RESPONSES"
"$fixture/config/sway/scripts/theme-picker.sh" >/dev/null
assert_unchanged
assert test ! -e "$THEME_LOG"

rm -f "$WOFI_CALLS" "$WOFI_PROMPTS" "$NOTIFY_LOG" "$THEME_LOG"
printf '%s\n%s\n\n' '✓ aws — AWS Cloud (dark)' 'Rotate wallpapers (timer)' > "$WOFI_RESPONSES"
"$fixture/config/sway/scripts/theme-picker.sh" >/dev/null
assert_unchanged
assert test ! -e "$THEME_LOG"

rm -f "$WOFI_CALLS" "$WOFI_PROMPTS" "$NOTIFY_LOG" "$THEME_LOG"
printf '%s\n%s\n' '✓ aws — AWS Cloud (dark)' 'Custom wallpaper (pick an image)' > "$WOFI_RESPONSES"
"$fixture/config/sway/scripts/theme-picker.sh" >/dev/null
assert_unchanged
assert test ! -e "$THEME_LOG"

rm -f "$fixture/themes/wallpapers/custom.jpg" "$WOFI_CALLS" "$WOFI_PROMPTS" "$NOTIFY_LOG" "$THEME_LOG"
printf '%s\n%s\n' '✓ aws — AWS Cloud (dark)' 'Rotate wallpapers (timer)' > "$WOFI_RESPONSES"
"$fixture/config/sway/scripts/theme-picker.sh" >/dev/null || true
assert rg -q 'add images before enabling rotation' "$NOTIFY_LOG"
assert_unchanged
assert test ! -e "$THEME_LOG"

rm -f "$WOFI_CALLS" "$WOFI_PROMPTS" "$NOTIFY_LOG" "$THEME_LOG"
printf '%s\n%s\n' '✓ aws — AWS Cloud (dark)' 'Custom wallpaper (pick an image)' > "$WOFI_RESPONSES"
"$fixture/config/sway/scripts/theme-picker.sh" >/dev/null || true
assert rg -q 'add images first' "$NOTIFY_LOG"
assert_unchanged
assert test ! -e "$THEME_LOG"

rm -f "$WOFI_CALLS" "$WOFI_PROMPTS" "$NOTIFY_LOG" "$THEME_LOG"
printf '%s\n\n' '✓ aws — AWS Cloud (dark)' > "$WOFI_RESPONSES"
"$fixture/config/sway/scripts/theme-picker.sh" >/dev/null
assert test ! -e "$THEME_LOG"

rm -f "$WOFI_CALLS" "$WOFI_PROMPTS" "$NOTIFY_LOG" "$THEME_LOG"
printf '%s\n%s\n' '✓ aws — AWS Cloud (dark)' 'Flat color' > "$WOFI_RESPONSES"
"$fixture/config/sway/scripts/theme-picker.sh" >/dev/null
assert_unchanged
assert rg -q 'Custom wallpaper will be preserved' "$NOTIFY_LOG"
assert rg -q 'current: aws' "$WOFI_PROMPTS"
assert rg -q 'current: custom wallpaper' "$WOFI_PROMPTS"
assert rg -q 'Flat color' "$WOFI_MENUS/2"
assert rg -q 'Theme default wallpaper' "$WOFI_MENUS/2"
assert rg -q 'Custom wallpaper \(pick an image\)' "$WOFI_MENUS/2"
assert rg -q 'Rotate wallpapers \(timer\)' "$WOFI_MENUS/2"
assert rg -q '^set aws --flat$' "$THEME_LOG"

printf 'PASS: theme picker tests\n'
