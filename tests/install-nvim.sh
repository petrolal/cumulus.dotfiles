#!/usr/bin/env bash
#
# Lifecycle tests for scripts/install-nvim.sh.
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

run_installer() {
  env \
    HOME="$1" \
    PATH="$TMP_DIR/bin:$PATH" \
    CUMULUS_NVIM_REPO_URL="file://$TMP_DIR/source" \
    CUMULUS_NVIM_DIR="$2" \
    "$REPO_ROOT/scripts/install-nvim.sh" "${@:3}"
}

mkdir -p "$TMP_DIR/source" "$TMP_DIR/bin"
git -C "$TMP_DIR/source" init -q
printf 'version-one\n' > "$TMP_DIR/source/version.txt"
git -C "$TMP_DIR/source" add version.txt
git -C "$TMP_DIR/source" -c user.name=test -c user.email=test@example.invalid \
  commit -q -m initial
printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP_DIR/bin/nvim"
chmod +x "$TMP_DIR/bin/nvim"

home="$TMP_DIR/home"
checkout="$TMP_DIR/checkout"
mkdir -p "$home"
run_installer "$home" "$checkout" >/dev/null
assert test -d "$checkout/.git"
assert test -L "$home/.config/nvim"
assert test "$(readlink -f "$home/.config/nvim")" = "$checkout"
assert test "$(git -C "$checkout" remote get-url origin)" = "file://$TMP_DIR/source"

printf 'version-two\n' > "$TMP_DIR/source/version.txt"
git -C "$TMP_DIR/source" add version.txt
git -C "$TMP_DIR/source" -c user.name=test -c user.email=test@example.invalid \
  commit -q -m update
run_installer "$home" "$checkout" >/dev/null
assert test "$(cat "$checkout/version.txt")" = "version-two"

rm "$home/.config/nvim"
mkdir -p "$home/.config/nvim"
printf 'keep this config\n' > "$home/.config/nvim/old.txt"
run_installer "$home" "$checkout" >/dev/null
assert test -L "$home/.config/nvim"
assert test -f "$home/.cumulus_backup"/*/.config/nvim/old.txt

other_config="$TMP_DIR/other-config"
mkdir -p "$other_config"
printf 'other target\n' > "$other_config/marker"
rm "$home/.config/nvim"
ln -s "$other_config" "$home/.config/nvim"
run_installer "$home" "$checkout" >/dev/null
assert test -L "$home/.config/nvim"
assert test "$(readlink -f "$home/.config/nvim")" = "$checkout"
wrong_link_found=false
for candidate in "$home/.cumulus_backup"/*/.config/nvim; do
  if [ -L "$candidate" ] && [ "$(readlink "$candidate")" = "$other_config" ]; then
    wrong_link_found=true
  fi
done
assert test "$wrong_link_found" = true

rm "$home/.config/nvim"
printf 'real file\n' > "$home/.config/nvim"
run_installer "$home" "$checkout" >/dev/null
assert test -L "$home/.config/nvim"
file_backup=("$home/.cumulus_backup"/*/.config/nvim)
assert test "${#file_backup[@]}" -ge 3
file_backup_found=false
for candidate in "${file_backup[@]}"; do
  if [ -f "$candidate" ] && [ "$(cat "$candidate")" = "real file" ]; then
    file_backup_found=true
  fi
done
assert test "$file_backup_found" = true

printf 'dirty\n' > "$checkout/local.txt"
run_installer "$home" "$checkout" >"$TMP_DIR/dirty.log" 2>&1
assert rg -q 'local changes; skipping git pull' "$TMP_DIR/dirty.log"
assert test -f "$checkout/local.txt"
rm "$checkout/local.txt"

non_git="$TMP_DIR/non-git"
mkdir -p "$non_git"
printf 'preserve\n' > "$non_git/marker"
if run_installer "$home" "$non_git" >/dev/null 2>&1; then
  printf 'FAIL: non-git checkout was accepted\n' >&2
  exit 1
fi
assert test -f "$non_git/marker"

fresh_home="$TMP_DIR/fresh-home"
run_installer "$fresh_home" "$checkout" >/dev/null
assert test -d "$fresh_home/.config"
assert test -L "$fresh_home/.config/nvim"

dry_home="$TMP_DIR/dry-home"
dry_checkout="$TMP_DIR/dry-checkout"
printf '#!/usr/bin/env bash\nprintf invoked > "%s"\nexit 42\n' \
  "$TMP_DIR/nvim-invoked" > "$TMP_DIR/bin/nvim"
chmod +x "$TMP_DIR/bin/nvim"
run_installer "$dry_home" "$dry_checkout" --dry-run >/dev/null
assert test ! -e "$dry_checkout"
assert test ! -e "$dry_home/.config"
assert test ! -e "$dry_home/.cumulus_backup"
assert test ! -e "$TMP_DIR/nvim-invoked"

printf '#!/usr/bin/env bash\nexit 42\n' > "$TMP_DIR/bin/nvim"
chmod +x "$TMP_DIR/bin/nvim"
run_installer "$home" "$checkout" --no-validate >/dev/null

failure_home="$TMP_DIR/failure-home"
failure_checkout="$TMP_DIR/failure-checkout"
if run_installer "$failure_home" "$failure_checkout" >/dev/null 2>&1; then
  printf 'FAIL: Neovim validation failure was accepted\n' >&2
  exit 1
fi
assert test -L "$failure_home/.config/nvim"

no_nvim_home="$TMP_DIR/no-nvim-home"
no_nvim_checkout="$TMP_DIR/no-nvim-checkout"
mkdir -p "$TMP_DIR/no-nvim-bin"
ln -sf "$(command -v git)" "$TMP_DIR/no-nvim-bin/git"
if env \
  HOME="$no_nvim_home" \
  PATH="$TMP_DIR/no-nvim-bin:/usr/bin:/bin" \
  CUMULUS_NVIM_REPO_URL="file://$TMP_DIR/source" \
  CUMULUS_NVIM_DIR="$no_nvim_checkout" \
  "$REPO_ROOT/scripts/install-nvim.sh" >"$TMP_DIR/no-nvim.log" 2>&1; then
  :
else
  printf 'FAIL: missing Neovim warning path failed\n' >&2
  exit 1
fi
assert rg -q 'nvim is not installed; skipping headless validation' "$TMP_DIR/no-nvim.log"

printf 'PASS: install-nvim lifecycle tests\n'
