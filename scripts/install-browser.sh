#!/usr/bin/env bash
#
# install-browser.sh — install Google Chrome, set it as the default
# browser (xdg-settings + xdg-mime, all the relevant MIME types/schemes),
# and print/verify the sway keybinding used to launch it.
#
# Ubuntu/Debian (apt): downloads Google's official .deb directly — its
# postinst script registers /etc/apt/sources.list.d/google-chrome.list so
# `apt upgrade` keeps Chrome current afterwards, no manual repo setup
# needed.
#
# Arch: Chrome itself isn't in the official repos (Google doesn't publish
# one) — installed via an AUR helper (yay or paru) if one is present,
# otherwise this prints the manual AUR steps and skips.
#
# Idempotent: safe to re-run; skips the download/install if Chrome is
# already present, and default-browser/MIME steps are re-applied either way
# (cheap, deterministic).
#
# Usage:
#   ./install-browser.sh            # install + set as default browser
#   ./install-browser.sh --dry-run  # preview commands, change nothing
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

log() { printf '\033[1;34m[browser]\033[0m %s\n' "$*"; }
run() { if $DRY_RUN; then echo "+ $*"; else eval "$@"; fi }

DESKTOP_FILE="google-chrome.desktop"

install_chrome_apt() {
  if command -v google-chrome-stable >/dev/null 2>&1 || command -v google-chrome >/dev/null 2>&1; then
    log "OK (already installed): google-chrome"
    return
  fi
  log "Downloading Google Chrome .deb..."
  run "curl -fsSL -o /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
  log "Installing (registers Google's apt repo for future updates)..."
  run "sudo apt update"
  run "sudo apt install -y /tmp/google-chrome-stable_current_amd64.deb"
  run "rm -f /tmp/google-chrome-stable_current_amd64.deb"
}

install_chrome_pacman() {
  if command -v google-chrome-stable >/dev/null 2>&1; then
    log "OK (already installed): google-chrome-stable"
    return
  fi
  local helper=""
  if command -v yay >/dev/null 2>&1; then
    helper=yay
  elif command -v paru >/dev/null 2>&1; then
    helper=paru
  fi
  if [ -z "$helper" ]; then
    log "No AUR helper (yay/paru) found — Chrome isn't in the official Arch repos."
    log "Install one first (e.g. https://github.com/Jguer/yay), then run:"
    log "  yay -S google-chrome"
    return
  fi
  log "Installing google-chrome from AUR via $helper..."
  run "$helper -S --needed --noconfirm google-chrome"
}

set_default_browser() {
  if ! command -v google-chrome-stable >/dev/null 2>&1 && ! command -v google-chrome >/dev/null 2>&1; then
    log "google-chrome not found on PATH — skipping default-browser setup."
    return
  fi
  if ! command -v xdg-settings >/dev/null 2>&1; then
    log "xdg-settings not found — install xdg-utils to set the default browser."
    return
  fi
  log "Setting $DESKTOP_FILE as the default browser..."
  run "xdg-settings set default-web-browser '$DESKTOP_FILE'"
  # xdg-settings alone doesn't always cover every URL scheme/MIME type
  # apps check — set the common ones explicitly too.
  local mime
  for mime in x-scheme-handler/http x-scheme-handler/https x-scheme-handler/about x-scheme-handler/unknown text/html application/xhtml+xml; do
    run "xdg-mime default '$DESKTOP_FILE' '$mime'"
  done
}

verify() {
  log "Default browser is now: $(xdg-settings get default-web-browser 2>/dev/null || echo unknown)"
  if grep -q 'exec google-chrome-stable' "$(dirname "$(readlink -f "$0")")/../config/sway/config" 2>/dev/null; then
    log "Sway keybinding OK: \$mod+Shift+b launches google-chrome-stable"
  else
    log "NOTE: no \$mod+Shift+b browser keybinding found in config/sway/config"
    log "      (expected if you haven't pulled the latest cumulus.dotfiles config yet)"
  fi
}

main() {
  $DRY_RUN && log "DRY RUN — no changes will be made"
  if command -v apt >/dev/null 2>&1; then
    install_chrome_apt
  elif command -v pacman >/dev/null 2>&1; then
    install_chrome_pacman
  else
    log "Neither apt nor pacman found — unsupported distro for this script."
    exit 1
  fi
  set_default_browser
  $DRY_RUN || verify
  log "Done. Launch Chrome with \$mod+Shift+b (after reloading sway: \$mod+Shift+c)."
}

main "$@"
