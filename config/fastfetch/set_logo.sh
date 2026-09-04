#!/usr/bin/env bash
set -e

[ -f /etc/os-release ] && . /etc/os-release

case "${ID:-linux}" in
arch) LOGO="polyonimo_arch_tetris.txt" ;;
ubuntu) LOGO="polyonimo_ubuntu_tetris.txt" ;;
*) LOGO="polyomino_tetris.txt" ;;
esac

ASSETS_DIR="$HOME/.config/fastfetch/assets"
mkdir -p "$ASSETS_DIR"
ln -sf "$ASSETS_DIR/$LOGO" "$ASSETS_DIR/current_logo.txt"
