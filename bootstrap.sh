#!/usr/bin/env bash
# cumulus.dotfiles Bootstrap Installer
# Minimal installer: Installs Java & Coursier only
# Full setup is handled by: cumulus install
set -euo pipefail

echo -e "\033[1;36m[cumulus bootstrap]\033[0m Starting cumulus.dotfiles installer..."
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

# Step 1: Detect package manager & install system dependencies
detect_pkg_mgr() {
  if command -v pacman &> /dev/null; then
    echo "pacman"
  elif command -v apt-get &> /dev/null; then
    echo "apt-get"
  elif command -v dnf &> /dev/null; then
    echo "dnf"
  else
    echo "unknown"
  fi
}

install_system_deps() {
  local pkg_mgr="$1"

  if [ "$pkg_mgr" = "unknown" ]; then
    echo -e "  \033[33m[NOTE]\033[0m Package manager not detected. Skipping system package installation."
    return
  fi

  echo -e "  \033[1;36m[cumulus]\033[0m Installing system dependencies for $pkg_mgr..."
  echo -e "  \033[33m[INFO]\033[0m You may be prompted for your sudo password..."

  case "$pkg_mgr" in
    pacman)
      # Core system + desktop + dev tools
      sudo pacman -S --needed --noconfirm \
        base-devel git curl wget \
        zsh fontconfig \
        sway waybar kitty wofi swaylock swayidle grim slurp \
        brightnessctl libpulse mako \
        chromium firefox \
        neovim \
        docker \
        ttf-jetbrains-mono-nerd
      echo -e "  \033[32m[OK]\033[0m System packages installed"
      ;;
    apt-get)
      sudo apt-get update
      sudo apt-get install -y \
        build-essential git curl wget \
        zsh fontconfig \
        sway waybar kitty wofi swaylock swayidle grim slurp \
        brightnessctl pulseaudio-utils mako \
        firefox chromium-browser \
        neovim \
        docker.io \
        fonts-jetbrains-mono
      echo -e "  \033[32m[OK]\033[0m System packages installed"
      ;;
    *)
      echo -e "  \033[33m[NOTE]\033[0m Package manager '$pkg_mgr' not automatically managed. Skipping installation."
      ;;
  esac
}

install_java() {
  if command -v java &> /dev/null; then
    echo -e "  \033[32m[OK]\033[0m Java already installed:"
    java -version 2>&1 | head -1
    return
  fi

  echo -e "  \033[1;36m[cumulus]\033[0m Installing Java (GraalVM 21)..."

  # Try to install via SDKMan
  if [ ! -d "$HOME/.sdkman" ]; then
    echo -e "  \033[36m[INFO]\033[0m Installing SDKMan..."
    curl -s "https://get.sdkman.io" | bash
  fi

  bash -c "
    source $HOME/.sdkman/bin/sdkman-init.sh
    sdk install java 21.0.1-graal --default 2>/dev/null || true
  "

  if command -v java &> /dev/null; then
    echo -e "  \033[32m[OK]\033[0m Java installed via SDKMan"
    java -version 2>&1 | head -1
  else
    echo -e "  \033[31m[ERROR]\033[0m Java installation failed"
    exit 1
  fi
}

install_coursier() {
  if command -v cs &> /dev/null; then
    echo -e "  \033[32m[OK]\033[0m Coursier already installed"
    cs --version 2>/dev/null || true
    return
  fi

  echo -e "  \033[1;36m[cumulus]\033[0m Installing Coursier..."

  mkdir -p "$BIN_DIR"

  case "$(uname -s)" in
    Linux)
      COURSIER_FILE="cs-x86_64-pc-linux.gz"
      ;;
    Darwin)
      COURSIER_FILE="cs-x86_64-apple-darwin.gz"
      ;;
    *)
      echo -e "  \033[33m[NOTE]\033[0m Unsupported platform for Coursier installation"
      return 1
      ;;
  esac

  curl -fL "https://github.com/coursier/launchers/raw/master/$COURSIER_FILE" | gzip -d > "$BIN_DIR/cs"
  chmod +x "$BIN_DIR/cs"

  echo -e "  \033[32m[OK]\033[0m Coursier installed to $BIN_DIR/cs"
  "$BIN_DIR/cs" update 2>/dev/null || true
}

enable_path() {
  if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo -e "  \033[36m[INFO]\033[0m Adding $BIN_DIR to PATH..."
    export PATH="$BIN_DIR:$PATH"

    # Also add SDKMan to PATH
    if [ -d "$HOME/.sdkman/bin" ]; then
      export PATH="$HOME/.sdkman/bin:$PATH"
    fi
  fi
}

# Main installation flow
PKG_MGR="$(detect_pkg_mgr)"

echo -e "  \033[36m[INFO]\033[0m Package manager: $PKG_MGR"
echo ""

# Install system dependencies
install_system_deps "$PKG_MGR"
echo ""

# Install Java
install_java
echo ""

# Install Coursier
install_coursier
echo ""

# Ensure PATH is set
enable_path
echo ""

# Installation complete
echo -e "\033[1;32m[SUCCESS]\033[0m Bootstrap complete!"
echo ""
echo -e "\033[1;36m[Next Steps]\033[0m"
echo -e "  1. Install cumulus from Maven Central:"
echo -e "     \033[33mcs install io.github.petrolal::cumulus:0.1.0 --name cumulus\033[0m"
echo ""
echo -e "  2. Run the interactive installer:"
echo -e "     \033[33mcumulus install\033[0m"
echo ""
echo -e "  3. Follow the interactive prompts to:"
echo -e "     - Choose your preferred tools and versions"
echo -e "     - Deploy dotfiles and symlinks"
echo -e "     - Run system health check"
echo ""
echo -e "\033[1;36m[INFO]\033[0m Ensure \$HOME/.local/bin is in your PATH:"
echo -e "  \033[33mexport PATH=\\\"\$HOME/.local/bin:\$PATH\\\"\033[0m"
echo ""
