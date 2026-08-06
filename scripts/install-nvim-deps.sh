#!/usr/bin/env bash
#
# install-nvim-deps.sh — install the latest Neovim plus everything its
# plugin ecosystem in this config needs:
#
#   - Neovim (latest stable release, from the official GitHub release tarball)
#   - luarocks (Lua package manager, used by some plugins to build Lua deps)
#   - ImageMagick (image preview/conversion, used by markdown/image plugins)
#   - mermaid-cli / mmdc (renders mermaid diagrams, e.g. in markdown preview)
#   - Python 3 + pip + pipx (for Python-based LSPs/tools, e.g. via Mason)
#   - nvm, then the latest Node.js + npm installed through it
#   - tree-sitter-cli (used by nvim-treesitter to build/update parsers)
#   - ripgrep (telescope.nvim's live_grep backend) + fd (telescope file finder)
#   - lazygit (terminal git UI, integrated into many nvim configs)
#   - lazydocker (terminal docker UI)
#
# NOTE on telescope.nvim: it's a Neovim *plugin*, not a system package — it's
# already declared in this config's lazy.nvim plugin spec and installs
# itself the first time Neovim starts. This script just makes sure its
# runtime dependencies (ripgrep, fd) are present.
#
# Supports Ubuntu (apt) and Arch (pacman). Anything not packaged by either
# (Neovim itself, tree-sitter-cli, mermaid-cli, lazygit, lazydocker) is
# installed from upstream release binaries/npm, identically on both distros.
#
# Usage:
#   ./install-nvim-deps.sh            # install everything below
#   ./install-nvim-deps.sh --dry-run  # preview commands, change nothing
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

log() { printf '\033[1;34m[nvim-deps]\033[0m %s\n' "$*"; }
run() { if $DRY_RUN; then echo "+ $*"; else eval "$@"; fi }

NVIM_INSTALL_DIR="/opt/nvim-linux-x86_64"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

install_system_packages() {
  if command -v apt >/dev/null 2>&1; then
    log "Installing base packages via apt..."
    run "sudo apt update"
    run "sudo apt install -y luarocks imagemagick python3 python3-pip python3-venv pipx ripgrep fd-find curl unzip build-essential"
    # Ubuntu ships fd as `fdfind` to avoid a name clash; symlink it to `fd`
    # since that's what telescope.nvim and most docs expect.
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
      run "mkdir -p '$HOME/.local/bin'"
      run "ln -sf \"\$(command -v fdfind)\" '$HOME/.local/bin/fd'"
    fi
  elif command -v pacman >/dev/null 2>&1; then
    log "Installing base packages via pacman..."
    run "sudo pacman -Syu --needed --noconfirm luarocks imagemagick python python-pip python-pipx ripgrep fd curl unzip base-devel"
  else
    log "No supported package manager found (apt/pacman) — install manually:"
    log "  luarocks imagemagick python3 pip pipx ripgrep fd curl unzip"
    exit 1
  fi
}

install_neovim() {
  local arch nvim_tag latest_url
  arch="$(uname -m)"
  if [ "$arch" != "x86_64" ]; then
    log "Unsupported arch for the prebuilt Neovim tarball ($arch) — install Neovim manually for your platform."
    return
  fi

  # Resolve the tag explicitly via the GitHub API instead of trusting the
  # /releases/latest redirect, which can be ambiguous (neovim also publishes
  # a floating "stable" tag/release alongside versioned tags like vX.Y.Z).
  # The API's "latest" release is defined as the most recent non-prerelease,
  # non-draft release, so this always resolves to the true latest stable
  # version tag (e.g. v0.12.4), never the nightly/prerelease build.
  nvim_tag="$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest \
    | grep -Po '"tag_name": *"\K[^"]+' || true)"

  if [ -n "$nvim_tag" ]; then
    log "Latest stable Neovim release: $nvim_tag"
    latest_url="https://github.com/neovim/neovim/releases/download/$nvim_tag/nvim-linux-x86_64.tar.gz"
  else
    log "WARN: could not resolve latest stable tag via GitHub API; falling back to the /releases/latest redirect."
    latest_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
  fi

  log "Downloading latest stable Neovim release..."
  run "curl -fL '$latest_url' -o /tmp/nvim-linux-x86_64.tar.gz"
  run "sudo rm -rf '$NVIM_INSTALL_DIR'"
  run "sudo tar -C /opt -xzf /tmp/nvim-linux-x86_64.tar.gz"
  run "sudo ln -sf '$NVIM_INSTALL_DIR/bin/nvim' /usr/local/bin/nvim"
  run "rm -f /tmp/nvim-linux-x86_64.tar.gz"

  if $DRY_RUN; then
    log "Neovim installed: (skipped in dry-run)"
  else
    log "Neovim installed: $("$NVIM_INSTALL_DIR/bin/nvim" --version | head -1)"
  fi
}

install_nvm_node() {
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    log "OK (already installed): nvm"
  else
    log "Installing nvm..."
    run "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash"
  fi

  if $DRY_RUN; then
    log "+ (dry-run) nvm install node --latest-npm && nvm alias default node"
    return
  fi

  # shellcheck disable=SC1091
  \. "$NVM_DIR/nvm.sh"
  log "Installing latest Node.js + npm via nvm..."
  nvm install node --latest-npm
  nvm alias default node
  log "Node: $(node -v)  npm: $(npm -v)"
}

install_npm_globals() {
  local npm_bin
  if $DRY_RUN; then
    log "+ npm install -g tree-sitter-cli @mermaid-js/mermaid-cli"
    return
  fi

  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  npm_bin="$(command -v npm || true)"
  if [ -z "$npm_bin" ]; then
    log "npm not found on PATH — skipping tree-sitter-cli/mermaid-cli (install Node first)"
    return
  fi

  log "Installing tree-sitter-cli and mermaid-cli via npm..."
  npm install -g tree-sitter-cli @mermaid-js/mermaid-cli
}

install_lazygit() {
  if command -v lazygit >/dev/null 2>&1; then
    log "OK (already installed): lazygit"
    return
  fi
  log "Installing lazygit (latest release)..."
  run "LAZYGIT_VERSION=\$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '\"tag_name\": *\"v\\K[^\"]*') && \
    curl -fLo /tmp/lazygit.tar.gz \"https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_\${LAZYGIT_VERSION}_linux_x86_64.tar.gz\" && \
    tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit && \
    mkdir -p '$HOME/.local/bin' && \
    install /tmp/lazygit '$HOME/.local/bin/lazygit' && \
    rm -f /tmp/lazygit.tar.gz /tmp/lazygit"
}

install_lazydocker() {
  if command -v lazydocker >/dev/null 2>&1; then
    log "OK (already installed): lazydocker"
    return
  fi
  log "Installing lazydocker (official install script)..."
  run "curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash"
}

main() {
  $DRY_RUN && log "DRY RUN — no changes will be made"

  install_system_packages
  install_neovim
  install_nvm_node
  install_npm_globals
  install_lazygit
  install_lazydocker

  log "Done."
  log "telescope.nvim is a plugin managed by this repo's nvim config (lazy.nvim)"
  log "— it will install/build itself the next time you launch nvim."
  log "Open a new shell (or 'source ~/.zshrc') to pick up nvm/node/npm on PATH."
}

main "$@"
