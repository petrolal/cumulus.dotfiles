#!/usr/bin/env bash
#
# update.sh — pull the latest cumulus.dotfiles and re-apply them.
#
# Usage:
#   update.sh              # git pull + re-run install.sh (no package install)
#   update.sh --packages   # also refresh packages
#
set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(cd "$(dirname "$SELF")/.." && pwd)"
log() { printf '\033[1;34m[update]\033[0m %s\n' "$*"; }

cd "$DOTFILES_DIR"

if [ -n "$(git status --porcelain)" ]; then
  log "You have local uncommitted changes in $DOTFILES_DIR:"
  git status --short
  log "Commit or stash them before updating, to avoid losing work."
  exit 1
fi

log "Pulling latest changes..."
git pull --ff-only

log "Re-running install.sh $*"
./install.sh "$@"

log "Update complete."
