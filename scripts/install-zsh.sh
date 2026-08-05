#!/usr/bin/env bash
#
# install-zsh.sh — install zsh + oh-my-zsh with the Cloud theme, ensure the
# Nerd Font (JetBrainsMono, used across kitty/waybar/wofi) is present via
# install-fonts.sh, and make Neovim the default editor system-wide.
#
# This script only installs the *framework* and fonts. The actual
# oh-my-zsh bootstrap + modular config loading lives in zsh/.zshrc and
# zsh/zsh_config/*.zsh in this repo — run install.sh afterwards (or first,
# order doesn't matter) to symlink those into place.
#
# Usage:
#   ./install-zsh.sh            # install everything below
#   ./install-zsh.sh --dry-run  # preview commands, change nothing
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

log() { printf '\033[1;34m[zsh]\033[0m %s\n' "$*"; }
run() { if $DRY_RUN; then echo "+ $*"; else eval "$@"; fi }

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPTS_DIR="$(dirname "$SELF")"

install_zsh() {
  if command -v zsh >/dev/null 2>&1; then
    log "OK (already installed): zsh"
    return
  fi
  if command -v apt >/dev/null 2>&1; then
    run "sudo apt update && sudo apt install -y zsh"
  elif command -v pacman >/dev/null 2>&1; then
    run "sudo pacman -Syu --needed --noconfirm zsh"
  else
    log "No supported package manager found (apt/pacman) — install zsh manually."
    exit 1
  fi
}

install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log "OK (already installed): oh-my-zsh"
    return
  fi
  log "Installing oh-my-zsh (unattended, keeping our own .zshrc)..."
  # RUNZSH=no: don't drop into a new shell mid-script.
  # KEEP_ZSHRC=yes: don't let the installer overwrite/backup our managed
  # .zshrc — this repo's install.sh symlinks its own afterwards anyway.
  # CHSH=no: don't fight this script's own chsh step below.
  run "RUNZSH=no KEEP_ZSHRC=yes CHSH=no sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
}

set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh || true)"
  [ -n "$zsh_path" ] || { log "zsh not found on PATH — skipping default shell change"; return; }

  if [ "${SHELL:-}" = "$zsh_path" ]; then
    log "OK (already default shell): zsh"
    return
  fi

  log "Setting zsh as default login shell..."
  if $DRY_RUN; then
    echo "+ chsh -s '$zsh_path' '$USER'"
    return
  fi

  if chsh -s "$zsh_path" "$USER" 2>/tmp/chsh-err.$$; then
    rm -f /tmp/chsh-err.$$
    return
  fi

  # `chsh` talks to the local /etc/passwd (and PAM) directly. On AD/LDAP/
  # SSSD-joined machines the account resolves via `getent`/NSS but chsh
  # still fails against it — observed as either "user does not exist in
  # /etc/passwd" or "PAM: Authentication failure" depending on the session.
  # Either way, fall back to `usermod`, which goes through NSS and works
  # with directory-backed accounts too.
  log "chsh failed (likely an AD/LDAP/SSSD-managed account, not local /etc/passwd):"
  sed 's/^/  /' /tmp/chsh-err.$$ >&2
  rm -f /tmp/chsh-err.$$
  log "Falling back to usermod..."
  if run "sudo usermod -s '$zsh_path' '$USER'"; then
    log "Default shell set via usermod."
  else
    log "WARN: could not change default shell (chsh and usermod both failed)."
    log "  This account is likely managed centrally (AD/LDAP) — ask your admin to"
    log "  update the loginShell attribute, or add: exec $zsh_path  to ~/.bash_profile"
  fi
}

install_nerd_font() {
  "$SCRIPTS_DIR/install-fonts.sh" $($DRY_RUN && echo --dry-run)
}

set_default_editor() {
  local nvim_path
  nvim_path="$(command -v nvim || true)"
  if [ -z "$nvim_path" ]; then
    log "nvim not found — install it first (see scripts/install-nvim-deps.sh), skipping default-editor setup"
    return
  fi

  log "Setting nvim as default editor (git core.editor)..."
  run "git config --global core.editor '$nvim_path'"

  if command -v update-alternatives >/dev/null 2>&1; then
    log "Registering nvim with update-alternatives (editor)..."
    run "sudo update-alternatives --install /usr/bin/editor editor '$nvim_path' 100"
    run "sudo update-alternatives --set editor '$nvim_path'"
  fi
  log "EDITOR/VISUAL are also exported from zsh/zsh_config/40-environment.zsh"
}

main() {
  $DRY_RUN && log "DRY RUN — no changes will be made"

  install_zsh
  install_oh_my_zsh
  set_default_shell
  install_nerd_font
  set_default_editor

  log "Done. Run ./install.sh to symlink zsh/.zshrc and zsh/zsh_config/ into place,"
  log "then open a new terminal (or 'exec zsh') to see the Cloud theme."
}

main "$@"
