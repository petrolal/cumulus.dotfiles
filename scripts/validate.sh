#!/usr/bin/env bash
#
# validate.sh — sanity-check that this dotfiles repo is correctly deployed.
#
# Meant to be run at the end of install.sh (automatic), or any time by hand
# to check the current state of the machine. Never modifies anything —
# read-only checks, each printed as OK / WARN / FAIL.
#
#   OK   — expected state confirmed.
#   WARN — optional/tool-dependent thing missing (not necessarily a problem,
#          e.g. a devops tool you never asked to install).
#   FAIL — something that should be true given what's installed isn't
#          (broken symlink, invalid config, etc).
#
# Exit code is non-zero if any FAIL was recorded (WARN doesn't affect it).
#
# Usage:
#   ./validate.sh          # run all checks, human-readable output
#   ./validate.sh --quiet  # only print WARN/FAIL lines (for cron/CI use)
#
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QUIET=false
FAIL_COUNT=0
WARN_COUNT=0

for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET=true ;;
    -h|--help) grep '^#' "$0" | sed 's/^#//'; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

ok()   { $QUIET || printf '  \033[1;32mOK\033[0m   %s\n' "$*"; }
warn() { WARN_COUNT=$((WARN_COUNT+1)); printf '  \033[1;33mWARN\033[0m %s\n' "$*"; }
fail() { FAIL_COUNT=$((FAIL_COUNT+1)); printf '  \033[1;31mFAIL\033[0m %s\n' "$*"; }
section() { $QUIET || printf '\033[1;34m==> %s\033[0m\n' "$*"; }

# Checks that $2 (a path under $HOME) is a symlink resolving into this repo.
check_link() {
  local dst="$HOME/$2" src="$DOTFILES_DIR/$1"
  if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
    fail "$2 does not exist"
  elif [ ! -L "$dst" ]; then
    fail "$2 exists but is not a symlink (real file/dir — install.sh would back it up before linking)"
  elif [ "$(readlink -f "$dst")" != "$(readlink -f "$src")" ]; then
    fail "$2 is a symlink but points elsewhere: $(readlink -f "$dst")"
  else
    ok "$2 -> repo ($1)"
  fi
}

check_cmd() {
  # check_cmd <label> <binary> [version-flag]
  local label="$1" bin="$2" flag="${3:---version}"
  if command -v "$bin" >/dev/null 2>&1; then
    ok "$label: $(timeout 5 "$bin" $flag 2>&1 | head -1)"
  else
    warn "$label not found ($bin) — install with the matching scripts/install-*.sh if you need it"
  fi
}

section "Symlinked configs"
check_link "zsh/.zshrc" ".zshrc"
check_link "zsh/zsh_config" ".config/dotfiles/zsh_config"
check_link "config/sway" ".config/sway"
check_link "config/wofi" ".config/wofi"
check_link "config/waybar" ".config/waybar"
check_link "config/kitty" ".config/kitty"

section "Scripts on PATH"
for script in "$DOTFILES_DIR"/scripts/*.sh; do
  [ -e "$script" ] || continue
  name="$(basename "$script" .sh)"
  cmd="$HOME/.local/bin/dotfiles-$name"
  if [ -L "$cmd" ] && [ "$(readlink -f "$cmd")" = "$(readlink -f "$script")" ]; then
    ok "dotfiles-$name"
  else
    fail "dotfiles-$name is missing or not linked to $script"
  fi
done
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ok "\$HOME/.local/bin is on \$PATH" ;;
  *) warn "\$HOME/.local/bin is not on \$PATH in this shell — dotfiles-* commands won't resolve" ;;
esac

section "Sway"
if command -v sway >/dev/null 2>&1; then
  ok "sway: $(sway --version)"
  if timeout 10 sway --validate -c "$HOME/.config/sway/config" >/tmp/sway-validate.$$ 2>&1; then
    ok "sway config validates"
  else
    fail "sway config failed validation (see: cat /tmp/sway-validate.$$)"
  fi
  rm -f "/tmp/sway-validate.$$"
else
  warn "sway not found — run ./install.sh --packages"
fi
check_cmd "wofi" wofi
check_cmd "waybar" waybar -v
check_cmd "kitty" kitty

section "Zsh"
if command -v zsh >/dev/null 2>&1; then
  ok "zsh: $(zsh --version)"
  if [ "$SHELL" = "$(command -v zsh)" ]; then
    ok "zsh is the default login shell"
  else
    warn "default login shell is \$SHELL=$SHELL, not zsh — run dotfiles-install-zsh or 'chsh -s \$(command -v zsh)'"
  fi
  if [ -d "$HOME/.oh-my-zsh" ]; then
    ok "oh-my-zsh installed"
  else
    warn "oh-my-zsh not installed — run dotfiles-install-zsh"
  fi
  zsh_out="$(timeout 10 zsh -i -c 'echo "$ZSH_THEME|$EDITOR"' 2>/tmp/zsh-validate.$$)"
  zsh_rc=$?
  if [ $zsh_rc -eq 0 ]; then
    theme="${zsh_out%%|*}"; editor="${zsh_out##*|}"
    ok "interactive zsh loads with no errors (ZSH_THEME=$theme, EDITOR=$editor)"
  else
    fail "interactive zsh startup produced an error (see: cat /tmp/zsh-validate.$$)"
  fi
  rm -f "/tmp/zsh-validate.$$"
else
  warn "zsh not found — run dotfiles-install-zsh"
fi
fc_count="$(fc-list 2>/dev/null | grep -ci "JetBrainsMono Nerd Font" || true)"
if [ "$fc_count" -gt 0 ]; then
  ok "JetBrainsMono Nerd Font installed"
else
  warn "JetBrainsMono Nerd Font not found — run dotfiles-install-zsh"
fi

section "Neovim"
check_cmd "neovim" nvim
check_cmd "luarocks" luarocks
check_cmd "ripgrep" rg
if command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1; then
  ok "fd/fdfind found"
else
  warn "fd not found — run dotfiles-install-nvim-deps"
fi
check_cmd "tree-sitter-cli" tree-sitter
check_cmd "lazygit" lazygit
check_cmd "lazydocker" lazydocker
check_cmd "node" node
check_cmd "npm" npm

section "DevOps tools"
check_cmd "docker" docker
if command -v docker >/dev/null 2>&1; then
  if id -nG "$USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
    ok "$USER is in the docker group"
  else
    warn "$USER is not in the docker group — run dotfiles-install-devops (re-login required after)"
  fi
fi
check_cmd "terraform" terraform version
check_cmd "ansible" ansible --version

section "Summary"
if [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
  echo "Everything checks out. ✅"
elif [ "$FAIL_COUNT" -eq 0 ]; then
  echo "No failures, $WARN_COUNT optional item(s) not installed (see WARN lines above)."
else
  echo "$FAIL_COUNT check(s) FAILED, $WARN_COUNT WARN — see above."
fi

exit $(( FAIL_COUNT > 0 ? 1 : 0 ))
