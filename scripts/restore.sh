#!/usr/bin/env bash
#
# restore.sh — restore a snapshot created by backup.sh.
#
# Usage:
#   restore.sh                       # restore the most recent snapshot
#   restore.sh <timestamp>.tar.gz    # restore a specific snapshot (see backup.sh --list)
#
set -euo pipefail

BACKUPS_DIR="$HOME/dotfiles-backups"
PRE_RESTORE_DIR="$HOME/.dotfiles_backup/pre-restore_$(date +%Y%m%d_%H%M%S)"
log() { printf '\033[1;34m[restore]\033[0m %s\n' "$*"; }

ARCHIVE_NAME="${1:-}"
if [ -z "$ARCHIVE_NAME" ]; then
  ARCHIVE_NAME="$(ls -1t "$BACKUPS_DIR" 2>/dev/null | head -1 || true)"
  if [ -z "$ARCHIVE_NAME" ]; then
    log "No snapshots found in $BACKUPS_DIR. Run backup.sh first."
    exit 1
  fi
  log "No snapshot specified, using most recent: $ARCHIVE_NAME"
fi

ARCHIVE="$BACKUPS_DIR/$ARCHIVE_NAME"
if [ ! -f "$ARCHIVE" ]; then
  log "Snapshot not found: $ARCHIVE"
  exit 1
fi

read -r -p "Restore $ARCHIVE over your current \$HOME config? Existing files will be moved to $PRE_RESTORE_DIR first. [y/N] " reply
case "$reply" in
  [yY]*) ;;
  *) log "Aborted."; exit 0 ;;
esac

mkdir -p "$PRE_RESTORE_DIR"
log "Snapshotting current state to $PRE_RESTORE_DIR before overwriting..."
for entry in $(tar -tzf "$ARCHIVE" | sed 's:/$::' | awk -F/ '{print $1"/"$2}' | sort -u); do
  if [ -e "$HOME/$entry" ]; then
    mkdir -p "$(dirname "$PRE_RESTORE_DIR/$entry")"
    cp -a "$HOME/$entry" "$PRE_RESTORE_DIR/$entry" 2>/dev/null || true
  fi
done

log "Extracting $ARCHIVE into \$HOME..."
tar -xzf "$ARCHIVE" -C "$HOME"

log "Done. Previous state saved at: $PRE_RESTORE_DIR"
log "Reload sway with: swaymsg reload   (or Mod+Shift+C)"
