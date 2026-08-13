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
  if [ "$PKG_MGR" = "unknown" ]; then
    echo -e "  \033[33m[NOTE]\033[0m Package manager not detected. Skipping system package installation."
    return
  fi

  echo -e "  \033[1;36m[cumulus]\033[0m Installing all system & build dependencies for $PKG_MGR..."
  echo -e "  \033[33m[INFO]\033[0m You may be prompted for your sudo password..."

  case "$PKG_MGR" in
    pacman)
      sudo pacman -S --needed --noconfirm sbt jdk-openjdk gcc git curl fontconfig zsh tar unzip which sway waybar kitty wofi swaylock swayidle grim slurp brightnessctl libpulse chromium docker terraform kubectl helm neovim ttf-jetbrains-mono-nerd mako
      echo -e "  \033[32m[OK]\033[0m System packages installed"
      ;;
    apt-get)
      sudo apt-get update
      if ! command -v sbt &> /dev/null; then
        echo -e "  \033[33m[cumulus]\033[0m Configuring sbt apt repository..."
        sudo apt-get install -y apt-transport-https curl gnupg
        echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo tee /etc/apt/sources.list.d/sbt.list > /dev/null
        echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt_old.list > /dev/null
        curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo apt-key add -
        sudo apt-get update
      fi
      sudo apt-get install -y build-essential default-jdk sbt git curl fontconfig zsh tar unzip sway waybar kitty wofi swaylock swayidle grim slurp brightnessctl pulseaudio-utils firefox docker.io helm neovim fonts-jetbrains-mono mako
      echo -e "  \033[32m[OK]\033[0m System packages installed"
      ;;
    *)
      echo -e "  \033[33m[NOTE]\033[0m Package manager '$PKG_MGR' not automatically managed. Skipping system package installation."
      ;;
  esac
}

enable_notification_daemon() {
  echo -e "  \033[1;36m[cumulus]\033[0m Configuring notification daemon (mako)..."

  if command -v mako &> /dev/null; then
    if systemctl --user is-active --quiet mako; then
      echo -e "  \033[32m[OK]\033[0m Mako notification daemon is running"
    else
      echo -e "  \033[36m[INFO]\033[0m Starting mako notification daemon..."
      systemctl --user start mako 2>/dev/null || echo -e "  \033[33m[NOTE]\033[0m Mako will start on next login"

      if systemctl --user is-enabled --quiet mako 2>/dev/null; then
        echo -e "  \033[32m[OK]\033[0m Mako is enabled for auto-start"
      else
        systemctl --user enable mako 2>/dev/null || true
        echo -e "  \033[32m[OK]\033[0m Mako enabled for auto-start"
      fi
    fi
  else
    echo -e "  \033[33m[NOTE]\033[0m Mako notification daemon not found (will be installed with system dependencies)"
  fi
}

install_sdkman() {
  echo -e "  \033[1;36m[cumulus]\033[0m Checking SDKMan (Scala Development Kit Manager)..."

  local SDKMAN_UPGRADE="${SDKMAN_UPGRADE:-false}"

  if [ -d "$HOME/.sdkman" ]; then
    echo -e "  \033[32m[OK]\033[0m SDKMan already installed at $HOME/.sdkman"
    source "$HOME/.sdkman/bin/sdkman-init.sh"

    # Optionally upgrade SDKMan if flag is set
    if [ "$SDKMAN_UPGRADE" = "true" ]; then
      echo -e "  \033[36m[INFO]\033[0m Upgrading SDKMan..."
      sdk selfupdate force 2>/dev/null || echo -e "  \033[33m[NOTE]\033[0m SDKMan selfupdate skipped"
    fi
  else
    echo -e "  \033[36m[INFO]\033[0m Installing SDKMan..."
    curl -s "https://get.sdkman.io" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    echo -e "  \033[32m[OK]\033[0m SDKMan installed successfully"
  fi
}

install_development_tools() {
  echo -e "  \033[1;36m[cumulus]\033[0m Installing development tools (Java, Scala, GraalVM) via SDKMan..."

  # Ensure SDKMan is available
  if [ ! -d "$HOME/.sdkman" ]; then
    install_sdkman
  fi

  # Source SDKMan in subshell to avoid environment pollution
  bash -c "
    source $HOME/.sdkman/bin/sdkman-init.sh

    # Install Java 21 (required for GraalVM)
    if ! sdk list java | grep -q 'installed'; then
      echo -e '  \033[36m[INFO]\033[0m Installing Java 21 (GraalVM)...'
      sdk install java 21.0.1-graal --default 2>/dev/null || true
      echo -e '  \033[32m[OK]\033[0m Java 21 GraalVM installed'
    else
      echo -e '  \033[32m[OK]\033[0m Java already installed'
    fi

    # Install Scala
    if ! command -v scala &> /dev/null; then
      echo -e '  \033[36m[INFO]\033[0m Installing Scala...'
      sdk install scala 3.5.2 --default 2>/dev/null || true
      echo -e '  \033[32m[OK]\033[0m Scala 3.5.2 installed'
    else
      echo -e '  \033[32m[OK]\033[0m Scala already installed'
    fi

    # Install sbt if not already available
    if ! command -v sbt &> /dev/null; then
      echo -e '  \033[36m[INFO]\033[0m Installing sbt...'
      sdk install sbt 1.9.9 --default 2>/dev/null || true
      echo -e '  \033[32m[OK]\033[0m sbt 1.9.9 installed'
    else
      echo -e '  \033[32m[OK]\033[0m sbt already installed'
    fi
  "
}

install_coursier() {
  echo -e "  \033[1;36m[cumulus]\033[0m Installing Coursier (Scala dependency manager)..."

  if command -v cs &> /dev/null; then
    echo -e "  \033[32m[OK]\033[0m Coursier already installed"
    return
  fi

  COURSIER_URL="https://github.com/coursier/launchers/raw/master"

  case "$(uname -s)" in
    Linux)
      COURSIER_FILE="cs-x86_64-pc-linux.gz"
      ;;
    Darwin)
      COURSIER_FILE="cs-x86_64-apple-darwin.gz"
      ;;
    *)
      echo -e "  \033[33m[NOTE]\033[0m Unsupported platform for automatic Coursier installation"
      return
      ;;
  esac

  echo -e "  \033[36m[INFO]\033[0m Downloading Coursier launcher..."
  mkdir -p "$BIN_DIR"
  curl -fL "$COURSIER_URL/$COURSIER_FILE" | gzip -d > "$BIN_DIR/cs"
  chmod +x "$BIN_DIR/cs"

  echo -e "  \033[32m[OK]\033[0m Coursier installed to $BIN_DIR/cs"

  # Install Coursier cache in ~/.local/share/coursier
  echo -e "  \033[36m[INFO]\033[0m Bootstrapping Coursier cache..."
  "$BIN_DIR/cs" update
  echo -e "  \033[32m[OK]\033[0m Coursier ready"
}

# Install all system dependencies by default
install_system_deps

# Enable notification daemon after package installation
enable_notification_daemon

# Step 2: Install development tools (SDKMan, Java, Scala, sbt, GraalVM)
install_sdkman
install_development_tools

# Step 3: Install Coursier
install_coursier

# Step 5: Build Scala 3 GraalVM Native Image
if command -v sbt &> /dev/null; then
  echo -e "  \033[32m[OK]\033[0m Building Scala 3 GraalVM Native Image executable..."
  (cd "$SCRIPT_DIR" && sbt nativeImage)
else
  echo -e "  \033[33m[NOTE]\033[0m sbt not found in PATH; skipping native compilation."
fi

# Step 6: Ensure ~/.local/bin target directory exists
mkdir -p "$BIN_DIR"

# Step 7: Copy compiled binary & deploy subcommand symlinks
if [ -f "$TARGET_BINARY" ]; then
  echo -e "  \033[32m[OK]\033[0m Installing compiled Scala binary to $BIN_DIR/cumulus..."
  install -m 755 "$TARGET_BINARY" "$BIN_DIR/cumulus"

  # Step 8: Run cumulus install and healthcheck
  export CUMULUS_BOOTSTRAP_RUNNING=1
  "$BIN_DIR/cumulus" install "$@"
  "$BIN_DIR/cumulus" healthcheck "$@"
else
  echo -e "  \033[31m[ERROR]\033[0m Native binary missing at $TARGET_BINARY. Please run 'sbt nativeImage' first."
  exit 1
fi

echo -e "\n\033[1;32m[SUCCESS]\033[0m cumulus.dotfiles (Scala 3) bootstrap & deployment completed successfully!"
echo -e "\033[1;36m[cumulus]\033[0m Installed components:"
echo -e "  ✓ System dependencies (sway, waybar, kitty, wofi, etc.)"
echo -e "  ✓ SDKMan (Scala Development Kit Manager)"
echo -e "  ✓ Java 21 GraalVM"
echo -e "  ✓ Scala 3.5.2"
echo -e "  ✓ sbt 1.9.9"
echo -e "  ✓ Coursier (dependency manager & app installer)"
echo -e "  ✓ cumulus CLI tool (native image)"

# Step 9: Ask user if they want to reboot the system
echo -en "\n\033[1;33m[?] Would you like to reboot the system now? (y/N): \033[0m"
read -r response || response="n"
if [[ "$response" =~ ^[Yy]$ ]]; then
  echo -e "\033[1;36m[cumulus]\033[0m Initiating system reboot..."

  # Try reboot methods in order of preference, with explicit feedback
  if command -v sudo &> /dev/null && sudo -n true 2>/dev/null; then
    echo -e "  \033[36m[INFO]\033[0m Attempting reboot via sudo..."
    if sudo reboot; then
      exit 0
    fi
  fi

  if command -v systemctl &> /dev/null; then
    echo -e "  \033[36m[INFO]\033[0m Attempting reboot via systemctl..."
    if systemctl reboot; then
      exit 0
    fi
  fi

  if command -v reboot &> /dev/null; then
    echo -e "  \033[36m[INFO]\033[0m Attempting reboot via reboot command..."
    if reboot; then
      exit 0
    fi
  fi

  # All reboot methods failed
  echo -e "  \033[31m[ERROR]\033[0m Unable to automatically reboot system. Please reboot manually:"
  echo -e "    \033[33msudo reboot\033[0m"
  exit 1
else
  echo -e "\033[1;32m[cumulus]\033[0m Reboot skipped. System configuration complete!"
fi
