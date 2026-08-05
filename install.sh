#!/usr/bin/env bash
#
# install.sh — deploy this dotfiles repo onto a fresh machine.
#
# What it does:
#   1. (Optionally) installs required packages via apt/pacman.
#   2. Symlinks every config file into place under $HOME.
#   3. Symlinks every scripts/*.sh into ~/.local/bin/dotfiles-<name> (on PATH).
#   4. Backs up any pre-existing real file/dir before symlinking over it.
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

# swaynag ships as part of the "sway" package on both Ubuntu and Arch, so it's
# not listed as a separate dependency here. jq/libnotify are needed by the
# scripts/ helpers (window screenshots, desktop notifications).
APT_PACKAGES=(sway wofi waybar kitty grim slurp wl-clipboard brightnessctl playerctl swaylock swayidle jq libnotify-bin)
PACMAN_PACKAGES=(sway wofi waybar kitty grim slurp wl-clipboard brightnessctl playerctl swaylock swayidle jq libnotify)
# Nerd Font used by wofi/waybar/kitty styling — only packaged in the AUR on Arch.
AUR_PACKAGES=(ttf-jetbrains-mono-nerd)

install_packages() {
  if command -v apt >/dev/null 2>&1; then
    log "Installing required packages via apt (Debian/Ubuntu)..."
    run "sudo apt update"
    run "sudo apt install -y ${APT_PACKAGES[*]}"
  elif command -v pacman >/dev/null 2>&1; then
    log "Installing required packages via pacman (Arch)..."
    run "sudo pacman -Syu --needed --noconfirm ${PACMAN_PACKAGES[*]}"
    if command -v yay >/dev/null 2>&1; then
      log "Installing AUR packages via yay..."
      run "yay -S --needed --noconfirm ${AUR_PACKAGES[*]}"
    elif command -v paru >/dev/null 2>&1; then
      log "Installing AUR packages via paru..."
      run "paru -S --needed --noconfirm ${AUR_PACKAGES[*]}"
    else
      log "No AUR helper (yay/paru) found — skipping: ${AUR_PACKAGES[*]}"
      log "Install an AUR helper or install these manually if you want the Nerd Font."
    fi
  else
    log "No supported package manager found (apt/pacman). Install manually:"
    log "  ${APT_PACKAGES[*]}"
    exit 1
  fi
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

link_scripts() {
  local bin_dir="$HOME/.local/bin"
  run "mkdir -p '$bin_dir'"
  run "chmod +x '$DOTFILES_DIR'/scripts/*.sh"

  local script name cmd
  for script in "$DOTFILES_DIR"/scripts/*.sh; do
    [ -e "$script" ] || continue
    name="$(basename "$script" .sh)"
    cmd="$bin_dir/dotfiles-$name"

    if [ -L "$cmd" ] && [ "$(readlink -f "$cmd")" = "$(readlink -f "$script")" ]; then
      log "OK (already linked): $cmd"
      continue
    fi
    run "rm -f '$cmd'"
    log "Linking $cmd -> $script"
    run "ln -s '$script' '$cmd'"
  done
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

  link_scripts

  log "Done. Backups (if any) saved under: $BACKUP_DIR"
  log "Reload sway with: swaymsg reload  (or Mod+Shift+C)"
  log "Reload zsh with:  source ~/.zshrc"
}

main "$@"
