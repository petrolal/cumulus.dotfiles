#!/usr/bin/env bash
#
# Tests for tracked theme-default wallpaper assets and state behavior.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP_DIR/bin/systemctl"
chmod +x "$TMP_DIR/bin/systemctl"
export PATH="$TMP_DIR/bin:$PATH"

assert() {
  if ! "$@"; then
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
  fi
}

flavors=(mocha macchiato frappe latte aws azure gcp oci)
for flavor in "${flavors[@]}"; do
  asset="$REPO_ROOT/themes/wallpapers/$flavor.svg"
  assert test -s "$asset"
  if git -C "$REPO_ROOT" check-ignore -q --no-index "$asset"; then
    printf 'FAIL: tracked SVG default is ignored: %s\n' "$asset" >&2
    exit 1
  fi
done

assert test -s "$REPO_ROOT/themes/wallpapers/ATTRIBUTION.md"
assert git -C "$REPO_ROOT" check-ignore -q themes/wallpapers/personal.png
if git -C "$REPO_ROOT" check-ignore -q themes/wallpapers/aws.svg; then
  printf 'FAIL: tracked SVG default is ignored\n' >&2
  exit 1
fi

home="$TMP_DIR/home"
mkdir -p "$home"
for flavor in "${flavors[@]}"; do
  env HOME="$home" "$REPO_ROOT/scripts/theme.sh" set "$flavor" --theme-default >/dev/null
  # shellcheck disable=SC1090
  source "$home/.config/cumulus/theme/state"
  assert test "$FLAVOR" = "$flavor"
  assert test "$MODE" = wallpaper
  assert test "$WALLPAPER_SOURCE" = theme-default
  assert test "$WALLPAPER" = "$REPO_ROOT/themes/wallpapers/$flavor.svg"
done

custom="$TMP_DIR/personal.png"
printf 'personal wallpaper\n' > "$custom"
env HOME="$home" "$REPO_ROOT/scripts/theme.sh" set aws --wallpaper "$custom" >/dev/null
env HOME="$home" "$REPO_ROOT/scripts/theme.sh" set azure --preserve-background >/dev/null
# shellcheck disable=SC1090
source "$home/.config/cumulus/theme/state"
assert test "$WALLPAPER_SOURCE" = user
assert test "$WALLPAPER" = "$custom"

custom_svg="$TMP_DIR/personal.svg"
printf '<svg/>\n' > "$custom_svg"
env HOME="$home" "$REPO_ROOT/scripts/theme.sh" set aws --wallpaper "$custom_svg" >/dev/null
env HOME="$home" "$REPO_ROOT/scripts/theme.sh" set azure --preserve-background >/dev/null
# shellcheck disable=SC1090
source "$home/.config/cumulus/theme/state"
assert test "$WALLPAPER_SOURCE" = user
assert test "$WALLPAPER" = "$custom_svg"

rm "$custom"
rm "$custom_svg"
env HOME="$home" "$REPO_ROOT/scripts/theme.sh" set gcp --preserve-background >/dev/null
# shellcheck disable=SC1090
source "$home/.config/cumulus/theme/state"
assert test "$WALLPAPER_SOURCE" = theme-default
assert test "$WALLPAPER" = "$REPO_ROOT/themes/wallpapers/gcp.svg"

rotation_repo="$TMP_DIR/rotation-repo"
cp -a "$REPO_ROOT" "$rotation_repo"
printf 'rotation wallpaper\n' > "$rotation_repo/themes/wallpapers/rotation.jpg"
printf 'ampersand wallpaper\n' > "$rotation_repo/themes/wallpapers/a&b.jpg"
rotation_home="$TMP_DIR/rotation-home"
env HOME="$rotation_home" "$rotation_repo/scripts/theme.sh" set aws --rotate --interval 45m >/dev/null
env HOME="$rotation_home" "$rotation_repo/scripts/theme.sh" next >/dev/null
env HOME="$rotation_home" "$rotation_repo/scripts/theme.sh" apply >/dev/null
env HOME="$rotation_home" "$rotation_repo/scripts/theme.sh" set azure --preserve-background >/dev/null
rotation_state="$rotation_home/.config/cumulus/theme/state"
assert rg -q '^MODE=rotate$' "$rotation_state"
assert rg -q '^INTERVAL=45m$' "$rotation_state"
assert rg -q '^WALLPAPER_SOURCE=rotate$' "$rotation_state"
rotation_wallpaper="$(rg '^WALLPAPER=' "$rotation_state" | cut -d= -f2-)"
assert test -f "$rotation_wallpaper"

fallback_repo="$TMP_DIR/fallback-repo"
cp -a "$REPO_ROOT" "$fallback_repo"
rm "$fallback_repo/themes/wallpapers/gcp.svg"
fallback_home="$TMP_DIR/fallback-home"
mkdir -p "$fallback_home/.config/cumulus/theme"
printf '%s\n' \
  'FLAVOR=aws' \
  'MODE=wallpaper' \
  'WALLPAPER=/missing/user wallpaper.png' \
  'WALLPAPER_SOURCE=user' \
  'INTERVAL=30m' \
  'NVIM_COLORSCHEME=aws-theme' \
  > "$fallback_home/.config/cumulus/theme/state"
env HOME="$fallback_home" "$fallback_repo/scripts/theme.sh" set gcp --preserve-background >/dev/null
# shellcheck disable=SC1090
source "$fallback_home/.config/cumulus/theme/state"
assert test "$MODE" = flat
assert test "$WALLPAPER" = ''
assert test "$WALLPAPER_SOURCE" = flat

safe_home="$TMP_DIR/safe-home"
mkdir -p "$safe_home/.config/cumulus/theme"
marker="$TMP_DIR/state-command-ran"
printf '%s\n' \
  'FLAVOR=aws' \
  'MODE=flat' \
  "WALLPAPER=\$(touch $marker)" \
  'WALLPAPER_SOURCE=flat' \
  'INTERVAL=30m' \
  'NVIM_COLORSCHEME=aws-theme' \
  > "$safe_home/.config/cumulus/theme/state"
env HOME="$safe_home" "$REPO_ROOT/scripts/theme.sh" current >/dev/null
assert test ! -e "$marker"

invalid_home="$TMP_DIR/invalid-state-home"
mkdir -p "$invalid_home/.config/cumulus/theme"
printf '%s\n' \
  'FLAVOR=../../tmp/should-not-run' \
  'MODE=flat' \
  'WALLPAPER=' \
  'WALLPAPER_SOURCE=flat' \
  'INTERVAL=30m' \
  > "$invalid_home/.config/cumulus/theme/state"
if env HOME="$invalid_home" "$REPO_ROOT/scripts/theme.sh" apply >/dev/null 2>&1; then
  printf 'FAIL: invalid saved flavor was accepted\n' >&2
  exit 1
fi

printf 'PASS: theme wallpaper tests\n'
