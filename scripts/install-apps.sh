#!/usr/bin/env bash
#
# install-apps.sh — install the "default applications" this workstation
# relies on, as referenced throughout config/sway/config (workspace
# assigns, tray helpers, launchers).
#
# NOTE: unlike install.sh, this script currently targets Ubuntu (apt + snap)
# only, since most entries here come from third-party apt repos already
# configured on this machine (Microsoft Edge, VS Code, Docker, GitHub CLI)
# or Canonical's snap store (Firefox, 1Password, IntelliJ IDEA, Obsidian,
# Telegram, Thunderbird). On Arch, install the closest AUR equivalents
# instead (e.g. `microsoft-edge-stable-bin`, `visual-studio-code-bin`,
# `obsidian`, `telegram-desktop`, `1password`, `intellij-idea-ultimate-edition`).
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

if ! command -v apt >/dev/null 2>&1; then
  log "apt not found — this script only supports Ubuntu/Debian right now."
  log "See the header comment for Arch/AUR equivalents."
  exit 1
fi

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

install_spotify_player() {
  # spotify-player / spotify-tui TUI clients referenced by ~/.config/spotify-player
  # and ~/.config/spotify-tui — installed via cargo, not apt/snap.
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
  install_apt
  install_snaps
  install_spotify_player
  log "Done. Add yourself to the docker group if needed: sudo usermod -aG docker \$USER (then re-login)"
}

main "$@"
