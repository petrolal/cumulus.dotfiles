#!/usr/bin/env bash
#
# install-nvim.sh — install and deploy the canonical Cumulus Neovim config.
#
# The dependency/toolchain installer is scripts/install-nvim-deps.sh. This
# script owns only the config repository and its ~/.config/nvim symlink.
#
# Usage:
#   ./install-nvim.sh                    # clone/update and deploy Cumulus Neovim
#   ./install-nvim.sh --dry-run          # preview without changing anything
#   ./install-nvim.sh --no-validate      # skip headless Neovim validation
#
set -euo pipefail

DRY_RUN=false
DO_VALIDATE=true
NVIM_REPO_URL="${CUMULUS_NVIM_REPO_URL:-https://github.com/petrolal/cumulus.nvim.git}"
NVIM_REPO_DIR="${CUMULUS_NVIM_DIR:-$HOME/cumulus.nvim}"
BACKUP_DIR=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --no-validate) DO_VALIDATE=false ;;
    -h|--help) grep '^#' "$0" | sed 's/^#//'; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

log() { printf '\033[1;34m[nvim]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[nvim] error:\033[0m %s\n' "$*" >&2; exit 1; }

run_cmd() {
  if $DRY_RUN; then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

normalize_url() {
  local url="$1"
  url="${url%.git}"
  url="${url#https://}"
  url="${url#http://}"
  url="${url#git@}"
  url="${url/:/\/}"
  printf '%s' "$url"
}

clone_or_update() {
  if [ -e "$NVIM_REPO_DIR" ] && [ ! -d "$NVIM_REPO_DIR/.git" ]; then
    die "Cumulus Neovim path exists but is not a git checkout: $NVIM_REPO_DIR"
  fi

  if [ ! -e "$NVIM_REPO_DIR" ]; then
    log "Cloning Cumulus Neovim from $NVIM_REPO_URL"
    run_cmd git clone "$NVIM_REPO_URL" "$NVIM_REPO_DIR"
    return
  fi

  local origin
  origin="$(git -C "$NVIM_REPO_DIR" remote get-url origin 2>/dev/null || true)"
  if [ "$(normalize_url "$origin")" != "$(normalize_url "$NVIM_REPO_URL")" ]; then
    if $DRY_RUN; then
      log "DRY RUN: would refuse origin mismatch: $origin"
      return
    fi
    die "Cumulus Neovim origin mismatch: $origin"
  fi

  if [ -n "$(git -C "$NVIM_REPO_DIR" status --porcelain)" ]; then
    log "WARN: Cumulus Neovim checkout has local changes; skipping git pull."
  else
    log "Updating Cumulus Neovim with fast-forward-only pull"
    run_cmd git -C "$NVIM_REPO_DIR" pull --ff-only
  fi
}

deploy_config() {
  local config_dir="$HOME/.config/nvim"
  if ! $DRY_RUN; then
    mkdir -p "$(dirname "$config_dir")"
  fi

  if [ -L "$config_dir" ] && [ "$(readlink -f "$config_dir" 2>/dev/null || true)" = "$(readlink -f "$NVIM_REPO_DIR" 2>/dev/null || true)" ]; then
    log "OK (already linked): $config_dir"
    return
  fi

  if [ -L "$config_dir" ] || [ -e "$config_dir" ]; then
    if $DRY_RUN; then
      BACKUP_DIR="$HOME/.cumulus_backup/$(date +%Y%m%d_%H%M%S).XXXXXX"
    else
      mkdir -p "$HOME/.cumulus_backup"
      BACKUP_DIR="$(mktemp -d "$HOME/.cumulus_backup/$(date +%Y%m%d_%H%M%S).XXXXXX")"
    fi
    log "Backing up existing Neovim config -> $BACKUP_DIR/.config/nvim"
    run_cmd mkdir -p "$BACKUP_DIR/.config"
    run_cmd mv "$config_dir" "$BACKUP_DIR/.config/nvim"
  fi

  log "Linking $config_dir -> $NVIM_REPO_DIR"
  run_cmd ln -s "$NVIM_REPO_DIR" "$config_dir"
}

validate_config() {
  $DRY_RUN && return 0
  $DO_VALIDATE || return 0
  if ! command -v nvim >/dev/null 2>&1; then
    log "WARN: nvim is not installed; skipping headless validation."
    return
  fi

  log "Running Neovim headless validation..."
  nvim --headless "+Lazy check" +qa ||
    die "Neovim validation failed; inspect the configuration before continuing."
}

main() {
  $DRY_RUN && log "DRY RUN — no changes will be made"
  log "Repository: $NVIM_REPO_DIR"
  clone_or_update
  deploy_config
  validate_config
  log "Cumulus Neovim installation complete."
}

main "$@"
