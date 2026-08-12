#!/usr/bin/env bash
# cumulus.dotfiles — Bootstrap installer (Scala 3 + GraalVM Native Image)
set -euo pipefail

echo -e "\033[1;36m[cumulus bootstrap]\033[0m Starting cumulus.dotfiles installer (Full Installation)..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
TARGET_BINARY="$SCRIPT_DIR/target/native-image/cumulus"

# Step 1: Detect package manager & install all system/build dependencies
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

PKG_MGR="$(detect_pkg_mgr)"

install_system_deps() {
  echo -e "  \033[1;36m[cumulus]\033[0m Installing all system & build dependencies for $PKG_MGR..."
  case "$PKG_MGR" in
    pacman)
      sudo pacman -S --needed --noconfirm sbt jdk-openjdk gcc git curl fontconfig zsh tar unzip which sway waybar kitty wofi swaylock swayidle grim slurp brightnessctl libpulse chromium docker terraform kubectl helm neovim ttf-jetbrains-mono-nerd || true
      ;;
    apt-get)
      sudo apt-get update || true
      if ! command -v sbt &> /dev/null; then
        echo -e "  \033[33m[cumulus]\033[0m Configuring sbt apt repository..."
        sudo apt-get install -y apt-transport-https curl gnupg || true
        echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo tee /etc/apt/sources.list.d/sbt.list || true
        echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt_old.list || true
        curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo apt-key add - 2>/dev/null || true
        sudo apt-get update || true
      fi
      sudo apt-get install -y build-essential default-jdk sbt git curl fontconfig zsh tar unzip sway waybar kitty wofi swaylock swayidle grim slurp brightnessctl pulseaudio-utils firefox docker.io helm neovim fonts-jetbrains-mono || true
      ;;
    *)
      echo -e "  \033[33m[NOTE]\033[0m Package manager '$PKG_MGR' not automatically managed. Skipping system package installation."
      ;;
  esac
}

# Install all system dependencies by default
install_system_deps

# Step 2: Ensure sbt / GraalVM build
if command -v sbt &> /dev/null; then
  echo -e "  \033[32m[OK]\033[0m Building Scala 3 GraalVM Native Image executable..."
  (cd "$SCRIPT_DIR" && sbt nativeImage)
else
  echo -e "  \033[33m[NOTE]\033[0m sbt not found in PATH; skipping native compilation."
fi

# Step 3: Ensure ~/.local/bin target directory exists
mkdir -p "$BIN_DIR"

# Step 4: Copy compiled binary & deploy subcommand symlinks
if [ -f "$TARGET_BINARY" ]; then
  echo -e "  \033[32m[OK]\033[0m Installing compiled Scala binary to $BIN_DIR/cumulus..."
  cp "$TARGET_BINARY" "$BIN_DIR/cumulus"
  chmod +x "$BIN_DIR/cumulus"
  
  # Step 5: Run cumulus install and validate health
  "$BIN_DIR/cumulus" install "$@"
  "$BIN_DIR/cumulus" validate "$@"
else
  echo -e "  \033[31m[ERROR]\033[0m Native binary missing at $TARGET_BINARY. Please run 'sbt nativeImage' first."
  exit 1
fi

echo -e "\n\033[1;32m[SUCCESS]\033[0m cumulus.dotfiles (Scala 3) bootstrap & deployment completed successfully!"

# Step 6: Ask user if they want to reboot the system
echo -en "\n\033[1;33m[?] Would you like to reboot the system now? (y/N): \033[0m"
read -r response || response="n"
if [[ "$response" =~ ^[Yy]$ ]]; then
  echo -e "\033[1;36m[cumulus]\033[0m Rebooting system..."
  sudo reboot || systemctl reboot || reboot
else
  echo -e "\033[1;32m[cumulus]\033[0m Reboot skipped. System configuration complete!"
fi
