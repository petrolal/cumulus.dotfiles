#!/usr/bin/env bash
# cumulus.dotfiles — Bootstrap installer (Scala 3 + GraalVM Native Image)
set -euo pipefail

echo -e "\033[1;36m[cumulus bootstrap]\033[0m Starting cumulus.dotfiles installer..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
TARGET_BINARY="$SCRIPT_DIR/target/native-image/cumulus"

# Step 1: Ensure sbt / GraalVM build
if command -v sbt &> /dev/null; then
  echo -e "  \033[32m[OK]\033[0m Building Scala 3 GraalVM Native Image executable..."
  (cd "$SCRIPT_DIR" && sbt nativeImage)
else
  echo -e "  \033[33m[NOTE]\033[0m sbt not found in PATH; skipping native compilation."
fi

# Step 2: Ensure ~/.local/bin target directory exists
mkdir -p "$BIN_DIR"

# Step 3: Copy compiled binary & deploy subcommand symlinks
if [ -f "$TARGET_BINARY" ]; then
  echo -e "  \033[32m[OK]\033[0m Installing compiled Scala binary to $BIN_DIR/cumulus..."
  cp "$TARGET_BINARY" "$BIN_DIR/cumulus"
  chmod +x "$BIN_DIR/cumulus"
  
  # Step 4: Run cumulus install to provision all 25 subcommand symlinks
  "$BIN_DIR/cumulus" install
else
  echo -e "  \033[31m[ERROR]\033[0m Native binary missing at $TARGET_BINARY. Please run 'sbt nativeImage' first."
  exit 1
fi

echo -e "\n\033[1;32m[SUCCESS]\033[0m cumulus.dotfiles (Scala 3) bootstrap & deployment completed successfully!"
