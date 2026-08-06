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

marker="$TMP_DIR/generated-command-ran"
dangerous="$TMP_DIR/\$(touch generated-command-ran);'wallpaper.png"
printf 'wallpaper\n' > "$dangerous"
(
  cd "$TMP_DIR"
  env HOME="$home" "$REPO_ROOT/scripts/theme.sh" set aws --wallpaper "$dangerous" >/dev/null
)
assert test ! -e "$marker"

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

invalid_source_home="$TMP_DIR/invalid-source-home"
mkdir -p "$invalid_source_home/.config/cumulus/theme"
printf '%s\n' \
  'FLAVOR=aws' \
  'MODE=wallpaper' \
  "WALLPAPER=$REPO_ROOT/themes/wallpapers/aws.svg" \
  'WALLPAPER_SOURCE=invalid' \
  'INTERVAL=30m' \
  'NVIM_COLORSCHEME=aws-theme' \
  > "$invalid_source_home/.config/cumulus/theme/state"
if env HOME="$invalid_source_home" "$REPO_ROOT/scripts/theme.sh" apply >/dev/null 2>&1; then
  printf 'FAIL: invalid wallpaper source was accepted\n' >&2
  exit 1
fi

invalid_mode_home="$TMP_DIR/invalid-mode-home"
mkdir -p "$invalid_mode_home/.config/cumulus/theme"
printf '%s\n' \
  'FLAVOR=aws' \
  'MODE=invalid' \
  'WALLPAPER=/missing.png' \
  'WALLPAPER_SOURCE=invalid' \
  'INTERVAL=30m' \
  > "$invalid_mode_home/.config/cumulus/theme/state"
env HOME="$invalid_mode_home" "$REPO_ROOT/scripts/theme.sh" apply >/dev/null
assert rg -q '^MODE=flat$' "$invalid_mode_home/.config/cumulus/theme/state"

publish_repo="$TMP_DIR/publish-repo"
cp -a "$REPO_ROOT" "$publish_repo"
publish_home="$TMP_DIR/publish-home"
env HOME="$publish_home" "$publish_repo/scripts/theme.sh" set aws --flat >/dev/null
before_sway="$(sha256sum "$publish_repo/config/sway/colors.conf")"
before_kitty="$(sha256sum "$publish_repo/config/kitty/colors.conf")"
mkdir -p "$TMP_DIR/publish-bin"
cat > "$TMP_DIR/publish-bin/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$*" == *"/render."*"/waybar.style.css"* ]]; then
  exit 1
fi
exec /bin/mv "$@"
EOF
chmod +x "$TMP_DIR/publish-bin/mv"
if PATH="$TMP_DIR/publish-bin:$PATH" HOME="$publish_home" \
  "$publish_repo/scripts/theme.sh" set azure --flat >/dev/null 2>&1; then
  printf 'FAIL: generated publication failure was accepted\n' >&2
  exit 1
fi
assert test "$(sha256sum "$publish_repo/config/sway/colors.conf")" = "$before_sway"
assert test "$(sha256sum "$publish_repo/config/kitty/colors.conf")" = "$before_kitty"

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
