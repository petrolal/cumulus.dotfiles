#!/usr/bin/env bash
#
# Rendering and flat-background tests for scripts/theme.sh.
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

mkdir -p "$TMP_DIR/bin"
printf '#!/usr/bin/env bash\nexit 1\n' > "$TMP_DIR/bin/gsettings"
chmod +x "$TMP_DIR/bin/gsettings"
export PATH="$TMP_DIR/bin:/usr/bin:/bin"
export HOME="$TMP_DIR/home"
mkdir -p "$HOME"

cloud_flavors=(aws azure gcp oci)
for flavor in "${cloud_flavors[@]}"; do
  "$REPO_ROOT/scripts/theme.sh" set "$flavor" --flat >/dev/null
  # shellcheck disable=SC1090
  source "$REPO_ROOT/themes/palettes/$flavor.sh"
  assert rg -q "window#waybar \{" "$REPO_ROOT/config/waybar/style.css"
  assert rg -q "background-color: $BASE;" "$REPO_ROOT/config/waybar/style.css"
  assert rg -q "exec_always swaybg -c \"$BASE\"" "$REPO_ROOT/config/sway/colors.conf"
  if rg -q '@@(BASE|TEXT|SUBTEXT0|SURFACE0|BLUE|RED|YELLOW)@@' "$REPO_ROOT/config/waybar/style.css"; then
    printf 'FAIL: unresolved Waybar placeholder for %s\n' "$flavor" >&2
    exit 1
  fi
  if rg -q '@@(BASE|TEXT|SURFACE0|BLUE)@@' "$REPO_ROOT/config/wofi/style.css"; then
    printf 'FAIL: unresolved Wofi placeholder for %s\n' "$flavor" >&2
    exit 1
  fi

  cp "$REPO_ROOT/config/sway/colors.conf" "$TMP_DIR/sway-$flavor.before"
  cp "$REPO_ROOT/config/waybar/style.css" "$TMP_DIR/waybar-$flavor.before"
  "$REPO_ROOT/scripts/theme.sh" set "$flavor" --flat >/dev/null
  cmp "$TMP_DIR/sway-$flavor.before" "$REPO_ROOT/config/sway/colors.conf"
  cmp "$TMP_DIR/waybar-$flavor.before" "$REPO_ROOT/config/waybar/style.css"
done

isolated="$TMP_DIR/invalid-repo"
cp -a "$REPO_ROOT" "$isolated"
cp "$isolated/config/waybar/style.css" "$TMP_DIR/invalid-before"
sed -i 's/@@BASE@@/BASE_REMOVED/g' "$isolated/config/waybar/style.css.tmpl"
if HOME="$TMP_DIR/invalid-home" "$isolated/scripts/theme.sh" set aws --flat \
  > "$TMP_DIR/invalid.log" 2>&1; then
  printf 'FAIL: invalid template was accepted\n' >&2
  exit 1
fi
assert rg -q 'missing placeholder @@BASE@@' "$TMP_DIR/invalid.log"
cmp "$TMP_DIR/invalid-before" "$isolated/config/waybar/style.css"

printf 'PASS: theme rendering tests\n'
