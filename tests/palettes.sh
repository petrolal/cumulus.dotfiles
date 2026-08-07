#!/usr/bin/env bash
#
# Palette contract and registry tests.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

required=(
  BASE MANTLE CRUST TEXT SUBTEXT1 SUBTEXT0 SURFACE0 SURFACE1 SURFACE2
  OVERLAY0 BLUE LAVENDER SAPPHIRE SKY TEAL GREEN YELLOW PEACH MAROON RED
  MAUVE PINK FLAMINGO ROSEWATER
)
flavors=(aws azure gcp oci)

for flavor in "${flavors[@]}"; do
  palette="$REPO_ROOT/themes/palettes/$flavor.sh"
  # shellcheck disable=SC1090
  source "$palette"
  assert_metadata=true
  [ "${THEME_NAME:-}" = "$flavor" ] || assert_metadata=false
  [ -n "${THEME_LABEL:-}" ] || assert_metadata=false
  [[ "${NVIM_COLORSCHEME:-}" =~ ^[A-Za-z0-9_.-]+$ ]] || assert_metadata=false
  if ! $assert_metadata; then
    printf 'FAIL: metadata contract for %s\n' "$flavor" >&2
    exit 1
  fi
  for var in "${required[@]}"; do
    value="${!var:-}"
    if [[ ! "$value" =~ ^#[[:xdigit:]]{6}$ ]]; then
      printf 'FAIL: %s has invalid %s=%s\n' "$flavor" "$var" "$value" >&2
      exit 1
    fi
  done
done

list_output="$TMP_DIR/list.txt"
"$REPO_ROOT/scripts/theme.sh" list > "$list_output"
for flavor in "${flavors[@]}"; do
  assert_count="$(rg -c "^  $flavor " "$list_output")"
  [ "$assert_count" -eq 1 ] || {
    printf 'FAIL: expected one registry entry for %s\n' "$flavor" >&2
    exit 1
  }
done

isolated="$TMP_DIR/repo"
cp -a "$REPO_ROOT" "$isolated"
sed -i '/^BLUE=/d' "$isolated/themes/palettes/aws.sh"
if HOME="$TMP_DIR/invalid-home" "$isolated/scripts/theme.sh" set aws --flat \
  > "$TMP_DIR/invalid.log" 2>&1; then
  printf 'FAIL: incomplete palette was accepted\n' >&2
  exit 1
fi
rg -q "missing required variable: BLUE" "$TMP_DIR/invalid.log"

printf 'PASS: palette contract tests\n'
