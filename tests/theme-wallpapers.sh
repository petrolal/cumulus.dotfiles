#!/usr/bin/env bash
#
# Tests for tracked theme-default wallpaper assets and state behavior.
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

rm "$custom"
env HOME="$home" "$REPO_ROOT/scripts/theme.sh" set gcp --preserve-background >/dev/null
# shellcheck disable=SC1090
source "$home/.config/cumulus/theme/state"
assert test "$WALLPAPER_SOURCE" = theme-default
assert test "$WALLPAPER" = "$REPO_ROOT/themes/wallpapers/gcp.svg"

printf 'PASS: theme wallpaper tests\n'
