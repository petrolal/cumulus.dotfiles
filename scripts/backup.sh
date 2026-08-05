#!/usr/bin/env bash
#
# backup.sh — snapshot the dotfiles-managed live config into a timestamped
# tarball, independent of git history. Useful right before risky experiments,
# or as an extra safety net alongside `install.sh`'s automatic backups.
#
# Usage:
#   backup.sh                 # snapshot to ~/dotfiles-backups/<timestamp>.tar.gz
#   backup.sh --list          # list existing snapshots
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUPS_DIR="$HOME/dotfiles-backups"
log() { printf '\033[1;34m[backup]\033[0m %s\n' "$*"; }

# Same target list install.sh manages — kept in sync manually since bash
# doesn't easily share associative arrays across scripts.
TARGETS=(
  ".zshrc"
  ".config/dotfiles/zsh_config"
  ".config/sway"
  ".config/wofi"
  ".config/waybar"
  ".config/kitty"
)

if [ "${1:-}" = "--list" ]; then
  log "Existing snapshots in $BACKUPS_DIR:"
  ls -1t "$BACKUPS_DIR" 2>/dev/null || echo "(none yet)"
  exit 0
fi

mkdir -p "$BACKUPS_DIR"
STAMP="$(date +%Y%m%d_%H%M%S)"
ARCHIVE="$BACKUPS_DIR/$STAMP.tar.gz"

EXISTING=()
for t in "${TARGETS[@]}"; do
  [ -e "$HOME/$t" ] && EXISTING+=("$t")
done

if [ "${#EXISTING[@]}" -eq 0 ]; then
  log "Nothing to back up — no managed targets found under \$HOME."
  exit 0
fi

log "Archiving: ${EXISTING[*]}"
tar -czhf "$ARCHIVE" -C "$HOME" "${EXISTING[@]}"
log "Saved: $ARCHIVE"
