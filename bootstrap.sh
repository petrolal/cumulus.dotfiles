#!/usr/bin/env bash
# bootstrap.sh — remote installer for cumulus.dotfiles (clones repo & hands off to cumulus install).
set -euo pipefail

REPO="${CUMULUS_REPO:-https://github.com/petrolal/cumulus.dotfiles.git}"
DIR="${CUMULUS_DIR:-$HOME/cumulus.dotfiles}"
REF="${CUMULUS_REF:-master}"

log()  { printf '\033[1;34m[bootstrap]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[bootstrap] error:\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -ne 0 ] || die "don't run this as root/sudo — run as your normal desktop user."
command -v git >/dev/null 2>&1 || die "git is required — install git first."

if [ -d "$DIR/.git" ]; then
  log "Existing checkout found at $DIR — updating..."
  git -C "$DIR" fetch --quiet origin "$REF"
  git -C "$DIR" checkout --quiet "$REF"
  git -C "$DIR" pull --quiet --ff-only origin "$REF"
elif [ -e "$DIR" ]; then
  die "$DIR exists and isn't a git checkout of this repo."
else
  log "Cloning $REPO -> $DIR ..."
  git clone --quiet --branch "$REF" "$REPO" "$DIR"
fi

if ! command -v cargo >/dev/null 2>&1; then
  log "Installing Rust toolchain (rustup) needed to build cumulus desktop binaries..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  export PATH="$HOME/.cargo/bin:$PATH"
fi

log "Handing off to cumulus-install in $DIR..."
exec cargo run --quiet --release --manifest-path "$DIR/rust/cumulus-dotfiles/Cargo.toml" --bin cumulus-install -- "$@"
