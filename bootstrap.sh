#!/usr/bin/env bash
#
# bootstrap.sh — one-line remote installer for cumulus.dotfiles.
#
# Meant to be piped straight into bash on a brand-new machine, before the
# repo is even cloned:
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/petrolal/cumulus.dotfiles/master/bootstrap.sh)
#
# All it does: make sure git is available, clone (or update, if already
# present) this repo into ~/cumulus.dotfiles, then exec its real install.sh
# with whatever flags you passed through. It never runs anything install.sh
# itself wouldn't — this is purely "get the repo, then hand off" glue.
#
# Usage (flags are forwarded verbatim to install.sh):
#   bash <(curl -fsSL .../bootstrap.sh)                          # symlink configs only
#   bash <(curl -fsSL .../bootstrap.sh) --packages --all-tools   # full fresh-machine setup
#   bash <(curl -fsSL .../bootstrap.sh) --dry-run --all-tools    # preview everything first
#
# Env overrides:
#   CUMULUS_REPO  git URL to clone (default: https://github.com/petrolal/cumulus.dotfiles.git)
#   CUMULUS_DIR   target directory (default: $HOME/cumulus.dotfiles)
#   CUMULUS_REF   branch/tag to check out (default: master)
#
set -euo pipefail

REPO="${CUMULUS_REPO:-https://github.com/petrolal/cumulus.dotfiles.git}"
DIR="${CUMULUS_DIR:-$HOME/cumulus.dotfiles}"
REF="${CUMULUS_REF:-master}"

log()  { printf '\033[1;34m[bootstrap]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[bootstrap] error:\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -ne 0 ] || die "don't run this as root/sudo — it sets up *your* desktop session (Sway/zsh/theme), not root's. Re-run as your normal user."

command -v git >/dev/null 2>&1 || die "git is required — install it first (e.g. 'sudo apt install -y git' or 'sudo pacman -S git')."

if [ -d "$DIR/.git" ]; then
  log "Existing checkout found at $DIR — updating instead of re-cloning."
  git -C "$DIR" fetch --quiet origin "$REF"
  git -C "$DIR" checkout --quiet "$REF"
  git -C "$DIR" pull --quiet --ff-only origin "$REF"
elif [ -e "$DIR" ]; then
  die "$DIR exists and isn't a git checkout of this repo — move it aside first, or set CUMULUS_DIR to another path."
else
  log "Cloning $REPO -> $DIR ..."
  git clone --quiet --branch "$REF" "$REPO" "$DIR"
fi

log "Handing off to $DIR/install.sh $*"
exec "$DIR/install.sh" "$@"
