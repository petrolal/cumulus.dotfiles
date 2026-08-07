#!/usr/bin/env bash
#
# install-apps.sh — install the "default applications" this workstation
# relies on, as referenced throughout config/sway/config (workspace
# assigns, tray helpers, launchers).
#
# Supports Ubuntu/Debian (apt + snap) and Arch (pacman + AUR via
# yay/paru).
#
# Usage:
#   ./install-apps.sh            # install everything below
#   ./install-apps.sh --dry-run  # preview commands, change nothing
#
set -euo pipefail

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h|--help) grep '^#' "$0" | sed 's/^#//'; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

log() { printf '\033[1;34m[apps]\033[0m %s\n' "$*"; }
run() { if $DRY_RUN; then echo "+ $*"; else eval "$@"; fi }

# ── Ubuntu/Debian (apt) ─────────────────────────────────────────────────
# Packages available directly via apt (some need the third-party repos this
# machine already has configured under /etc/apt/sources.list.d/).
APT_PACKAGES=(
  microsoft-edge-stable   # /etc/apt/sources.list.d/microsoft-edge.sources
  code                    # /etc/apt/sources.list.d/vscode.sources
  gh                      # /etc/apt/sources.list.d/github-cli.list
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  thunderbird             # transitional package -> installs the thunderbird snap
  network-manager-gnome   # nm-applet, network tray indicator
  blueman                 # blueman-applet, bluetooth tray indicator
  sway-notification-center # swaync
  policykit-1             # polkit auth agent (pkexec)
)

# Apps only distributed as snaps (or best installed that way on Ubuntu).
SNAP_PACKAGES=(firefox telegram-desktop)
SNAP_CLASSIC_PACKAGES=(1password intellij-idea obsidian yazi)

# ── Arch (pacman + AUR) ──────────────────────────────────────────────────
# Packages available directly in the official repos.
PACMAN_PACKAGES=(
  github-cli              # gh
  docker docker-buildx docker-compose
  thunderbird
  network-manager-applet  # nm-applet, network tray indicator
  blueman                 # blueman-applet, bluetooth tray indicator
  polkit                  # polkit auth agent (pkexec)
  firefox
  telegram-desktop
  yazi
)

# Packages that only exist in the AUR (installed via yay/paru if available).
AUR_PACKAGES=(
  microsoft-edge-stable-bin
  visual-studio-code-bin
  sway-notification-center
  1password
  intellij-idea-ultimate-edition
  obsidian
)

install_apt() {
  log "Installing apt packages: ${APT_PACKAGES[*]}"
  run "sudo apt update"
  run "sudo apt install -y ${APT_PACKAGES[*]}"
}

install_snaps() {
  command -v snap >/dev/null 2>&1 || { log "snapd not found — skipping snap installs"; return; }

  for pkg in "${SNAP_PACKAGES[@]}"; do
    log "Installing snap: $pkg"
    run "sudo snap install '$pkg'"
  done
  for pkg in "${SNAP_CLASSIC_PACKAGES[@]}"; do
    log "Installing snap (classic): $pkg"
    run "sudo snap install '$pkg' --classic"
  done
}

install_pacman() {
  log "Installing pacman packages: ${PACMAN_PACKAGES[*]}"
  run "sudo pacman -Syu --needed --noconfirm ${PACMAN_PACKAGES[*]}"
}

install_aur() {
  local helper=""
  if command -v yay >/dev/null 2>&1; then
    helper=yay
  elif command -v paru >/dev/null 2>&1; then
    helper=paru
  fi
  if [ -z "$helper" ]; then
    log "No AUR helper (yay/paru) found — skipping: ${AUR_PACKAGES[*]}"
    log "Install an AUR helper (e.g. https://github.com/Jguer/yay), then run:"
    log "  yay -S ${AUR_PACKAGES[*]}"
    return
  fi
  log "Installing AUR packages via $helper: ${AUR_PACKAGES[*]}"
  run "$helper -S --needed --noconfirm ${AUR_PACKAGES[*]}"
}

install_spotify_player() {
  # spotify-player / spotify-tui TUI clients referenced by ~/.config/spotify-player
  # and ~/.config/spotify-tui — installed via cargo, not apt/pacman/snap.
  if ! command -v cargo >/dev/null 2>&1; then
    log "cargo not found — skipping spotify_player (install Rust first: https://rustup.rs)"
    return
  fi
  if command -v spotify_player >/dev/null 2>&1; then
    log "OK (already installed): spotify_player"
    return
  fi
  log "Installing spotify_player via cargo..."
  run "cargo install spotify_player"
}

main() {
  $DRY_RUN && log "DRY RUN — no changes will be made"

  if command -v apt >/dev/null 2>&1; then
    install_apt
    install_snaps
  elif command -v pacman >/dev/null 2>&1; then
    install_pacman
    install_aur
  else
    log "No supported package manager found (apt/pacman) — install manually:"
    log "  ${APT_PACKAGES[*]}"
    exit 1
  fi

  install_spotify_player
  log "Done. Add yourself to the docker group if needed: sudo usermod -aG docker \$USER (then re-login)"
}

main "$@"
