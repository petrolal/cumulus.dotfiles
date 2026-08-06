#!/usr/bin/env bash
#
# Tests for complete, data-only, migration-safe theme state handling.
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
printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP_DIR/bin/systemctl"
chmod +x "$TMP_DIR/bin/systemctl"
export PATH="$TMP_DIR/bin:$PATH"

home="$TMP_DIR/home"
mkdir -p "$home"
wallpaper="$TMP_DIR/wall paper & image.png"
printf 'wallpaper\n' > "$wallpaper"
env HOME="$home" "$REPO_ROOT/scripts/theme.sh" set aws --wallpaper "$wallpaper" >/dev/null
env HOME="$home" "$REPO_ROOT/scripts/theme.sh" apply >/dev/null
state="$home/.config/cumulus/theme/state"
for key in FLAVOR MODE WALLPAPER WALLPAPER_SOURCE INTERVAL NVIM_COLORSCHEME; do
  assert rg -q "^$key=" "$state"
done
assert rg -q "^WALLPAPER=$wallpaper$" "$state"

legacy_home="$TMP_DIR/legacy-home"
mkdir -p "$legacy_home/.config/cumulus/theme"
printf '%s\n' \
  'FLAVOR=aws' \
  'MODE=wallpaper' \
  "WALLPAPER=$REPO_ROOT/themes/wallpapers/aws.svg" \
  'INTERVAL=30m' \
  > "$legacy_home/.config/cumulus/theme/state"
env HOME="$legacy_home" "$REPO_ROOT/scripts/theme.sh" apply >/dev/null
legacy_state="$legacy_home/.config/cumulus/theme/state"
for key in FLAVOR MODE WALLPAPER WALLPAPER_SOURCE INTERVAL NVIM_COLORSCHEME; do
  assert rg -q "^$key=" "$legacy_state"
done
assert rg -q '^WALLPAPER_SOURCE=theme-default$' "$legacy_state"
assert rg -q '^NVIM_COLORSCHEME=aws-theme$' "$legacy_state"

marker="$TMP_DIR/state-command-ran"
malicious_home="$TMP_DIR/malicious-home"
mkdir -p "$malicious_home/.config/cumulus/theme"
printf '%s\n' \
  'FLAVOR=aws' \
  'MODE=flat' \
  "WALLPAPER=\$(touch $marker)" \
  'WALLPAPER_SOURCE=flat' \
  'INTERVAL=30m' \
  'NVIM_COLORSCHEME=aws-theme' \
  > "$malicious_home/.config/cumulus/theme/state"
env HOME="$malicious_home" "$REPO_ROOT/scripts/theme.sh" apply >/dev/null
assert test ! -e "$marker"

printf 'PASS: state safety tests\n'
