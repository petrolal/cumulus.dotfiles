#!/usr/bin/env bash
#
# install.sh — deploy cumulus.dotfiles onto a fresh machine.
#
# What it does:
#   1. Installs required packages via apt/pacman (default enabled; skip with --no-packages or --links-only).
#   2. Symlinks every config file into place under $HOME.
#   3. Symlinks every scripts/*.sh into ~/.local/bin/cumulus-<name> (on PATH).
#   4. Backs up any pre-existing real file/dir before symlinking over it.
#   5. Installs the JetBrainsMono Nerd Font (unconditionally — kitty/waybar/
#      wofi/sway configs hardcode it, so icons render as boxes without it)
#      — see scripts/install-fonts.sh.
#   6. Applies the saved theme (Catppuccin flavor + flat color/wallpaper/
#      rotation), or the default (mocha / flat) on first run — see
#      scripts/theme.sh.
#   7. Deploys Cumulus Neovim & deps (default enabled; skip with --no-nvim or --links-only).
#   8. (Optionally) runs additional tool installers (--zsh, --apps, --devops, --browser, --all-tools).
#   9. Runs scripts/validate.sh at the end to confirm everything is correctly
#      in place (skipped in --dry-run, or with --no-validate).
#
# Usage:
#   ./install.sh              # full default setup (packages + configs + fonts + theme + cumulus.nvim)
#   ./install.sh --links-only # symlink configs only (no package or tool installations)
#   ./install.sh --no-packages # skip apt/pacman package installation
#   ./install.sh --no-nvim     # skip Neovim & cumulus.nvim deployment
#   ./install.sh --zsh        # also run scripts/install-zsh.sh
#   ./install.sh --apps       # also run scripts/install-apps.sh
#   ./install.sh --devops     # also run scripts/install-devops.sh (docker/terraform/ansible)
#   ./install.sh --browser    # also run scripts/install-browser.sh (Google Chrome + default browser)
#   ./install.sh --all-tools  # auto-discover and run every scripts/install-*.sh
#   ./install.sh --no-validate # skip the final scripts/validate.sh run
#   ./install.sh --dry-run    # show what would happen, change nothing (forwarded to installers too)
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.cumulus_backup/$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false
DO_PACKAGES=true
DO_ZSH=false
DO_NVIM=true
DO_APPS=false
DO_DEVOPS=false
DO_BROWSER=false
DO_ALL_TOOLS=false
DO_VALIDATE=true

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --packages) DO_PACKAGES=true ;;
    --no-packages) DO_PACKAGES=false ;;
    --nvim) DO_NVIM=true ;;
    --no-nvim) DO_NVIM=false ;;
    --links-only)
      DO_PACKAGES=false
      DO_NVIM=false
      DO_ZSH=false
      DO_APPS=false
      DO_DEVOPS=false
      DO_BROWSER=false
      DO_ALL_TOOLS=false
      ;;
    --zsh) DO_ZSH=true ;;
    --apps) DO_APPS=true ;;
    --devops) DO_DEVOPS=true ;;
    --browser) DO_BROWSER=true ;;
    --all-tools) DO_ALL_TOOLS=true ;;
    --no-validate) DO_VALIDATE=false ;;
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
  ["zsh/zsh_config"]=".config/cumulus/zsh_config"
  ["config/sway"]=".config/sway"
  ["config/wofi"]=".config/wofi"
  ["config/waybar"]=".config/waybar"
  ["config/kitty"]=".config/kitty"
)

# swaynag ships as part of the "sway" package on both Ubuntu and Arch, so it's
# not listed as a separate dependency here. jq/libnotify are needed by the
# scripts/ helpers (window screenshots, desktop notifications).
APT_PACKAGES=(sway wofi waybar kitty grim slurp wl-clipboard brightnessctl playerctl swaylock swayidle wdisplays jq libnotify-bin)
PACMAN_PACKAGES=(sway wofi waybar kitty grim slurp wl-clipboard brightnessctl playerctl swaylock swayidle wdisplays jq libnotify)
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
    cmd="$bin_dir/cumulus-$name"

    if [ -L "$cmd" ] && [ "$(readlink -f "$cmd")" = "$(readlink -f "$script")" ]; then
      log "OK (already linked): $cmd"
      continue
    fi
    run "rm -f '$cmd'"
    log "Linking $cmd -> $script"
    run "ln -s '$script' '$cmd'"
  done
}

run_installer() {
  local script="$DOTFILES_DIR/scripts/$1"
  local extra_args=()
  $DRY_RUN && extra_args+=(--dry-run)
  if [ "$1" = "install-nvim.sh" ] && ! $DO_VALIDATE; then
    extra_args+=(--no-validate)
  fi

  log "Running $1 ${extra_args[*]:-}"
  if $DRY_RUN; then
    echo "+ '$script' ${extra_args[*]:-}"
  else
    "$script" "${extra_args[@]}"
  fi
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

  if ! $DRY_RUN; then
    log "Ensuring Nerd Font is installed (needed by kitty/waybar/wofi/sway configs)..."
    "$DOTFILES_DIR/scripts/install-fonts.sh"
  else
    log "+ '$DOTFILES_DIR/scripts/install-fonts.sh'"
  fi

  if ! $DRY_RUN; then
    log "Applying theme (flavor + background mode)..."
    "$DOTFILES_DIR/scripts/theme.sh" apply
  else
    log "+ '$DOTFILES_DIR/scripts/theme.sh' apply"
  fi

  if $DO_ALL_TOOLS; then
    local installer
    for installer in "$DOTFILES_DIR"/scripts/install-*.sh; do
      [ -e "$installer" ] || continue
      run_installer "$(basename "$installer")"
    done
  else
    $DO_ZSH    && run_installer install-zsh.sh
    if $DO_NVIM; then
      run_installer install-nvim-deps.sh
      run_installer install-nvim.sh
    fi
    $DO_APPS   && run_installer install-apps.sh
    $DO_DEVOPS && run_installer install-devops.sh
    $DO_BROWSER && run_installer install-browser.sh
  fi

  log "Done. Backups (if any) saved under: $BACKUP_DIR"
  log "Reload sway with: swaymsg reload  (or Mod+Shift+C)"
  log "Reload zsh with:  source ~/.zshrc"

  if ! $DRY_RUN && $DO_VALIDATE; then
    log "Running validation checks..."
    echo
    "$DOTFILES_DIR/scripts/validate.sh" || log "Validation reported issues — see FAIL lines above."
  fi
}

main "$@"
