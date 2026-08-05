#!/usr/bin/env bash
#
# install.sh — deploy this dotfiles repo onto a fresh machine.
#
# What it does:
#   1. (Optionally) installs required packages via apt.
#   2. Symlinks every config file into place under $HOME.
#   3. Backs up any pre-existing real file/dir before symlinking over it.
#
# Usage:
#   ./install.sh            # symlink configs only
#   ./install.sh --packages # also apt-install required packages first
#   ./install.sh --dry-run  # show what would happen, change nothing
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false
DO_PACKAGES=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --packages) DO_PACKAGES=true ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^#//'
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

log()  { printf '\033[1;34m[install]\033[0m %s\n' "$*"; }
run()  { if $DRY_RUN; then echo "+ $*"; else eval "$@"; fi }

# Map of "source (relative to this repo)" -> "destination (relative to $HOME)"
declare -A LINKS=(
  ["zsh/.zshrc"]=".zshrc"
  ["zsh/.zshrc_custom"]=".zshrc_custom"
  ["config/sway"]=".config/sway"
  ["config/wofi"]=".config/wofi"
  ["config/waybar"]=".config/waybar"
  ["config/kitty"]=".config/kitty"
)

REQUIRED_PACKAGES=(sway wofi waybar kitty grim slurp wl-clipboard brightnessctl playerctl swaylock swayidle swaynag)

install_packages() {
  log "Installing required packages via apt..."
  run "sudo apt update"
  run "sudo apt install -y ${REQUIRED_PACKAGES[*]}"
}

link_one() {
  local src="$DOTFILES_DIR/$1"
  local dst="$HOME/$2"

  if [ ! -e "$src" ]; then
    log "SKIP (missing in repo): $1"
    return
  fi

  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    if [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
      log "OK (already linked): $dst"
      return
    fi
    log "Replacing existing symlink: $dst"
    run "rm -f '$dst'"
  elif [ -e "$dst" ]; then
    log "Backing up existing $dst -> $BACKUP_DIR/$2"
    run "mkdir -p '$(dirname "$BACKUP_DIR/$2")'"
    run "mv '$dst' '$BACKUP_DIR/$2'"
  fi

  log "Linking $dst -> $src"
  run "ln -s '$src' '$dst'"
}

main() {
  log "Dotfiles repo: $DOTFILES_DIR"
  $DRY_RUN && log "DRY RUN — no changes will be made"

  if $DO_PACKAGES; then
    install_packages
  fi

  for src in "${!LINKS[@]}"; do
    link_one "$src" "${LINKS[$src]}"
  done

  log "Done. Backups (if any) saved under: $BACKUP_DIR"
  log "Reload sway with: swaymsg reload  (or Mod+Shift+C)"
  log "Reload zsh with:  source ~/.zshrc"
}

main "$@"
