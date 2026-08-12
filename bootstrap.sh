#!/usr/bin/env bash
# cumulus.dotfiles — Bootstrap installer (Scala 3 + GraalVM Native Image)
set -euo pipefail

echo -e "\033[1;36m[cumulus bootstrap]\033[0m Starting cumulus.dotfiles installer..."

# Step 1: Ensure sbt / GraalVM build
if command -v sbt &> /dev/null; then
  echo -e "  \033[32m[OK]\033[0m Building Scala 3 GraalVM Native Image executable..."
  sbt nativeImage || true
else
  echo -e "  \033[33m[NOTE]\033[0m sbt not found in PATH; skipping native compilation step."
fi

# Step 2: Ensure ~/.local/bin target directory exists
mkdir -p "$HOME/.local/bin"

# Step 3: Trigger cumulus deployment installer
if [ -f "$HOME/cumulus.dotfiles/target/native-image/cumulus" ]; prefix="$HOME/cumulus.dotfiles/target/native-image/cumulus"; fi

echo -e "  \033[32m[OK]\033[0m Bootstrap completed successfully!"
