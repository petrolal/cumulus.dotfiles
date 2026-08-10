#!/usr/bin/env bash
# install.sh — thin bootstrapper that compiles & hands off to cumulus-install (Rust).
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v cargo >/dev/null 2>&1; then
  exec cargo run --quiet --release --manifest-path "$DOTFILES_DIR/rust/cumulus-dotfiles/Cargo.toml" --bin cumulus-install -- "$@"
else
  echo "[install] error: cargo (Rust toolchain) is required. Install rustup from https://rustup.rs" >&2
  exit 1
fi
