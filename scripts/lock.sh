#!/usr/bin/env bash
#
# lock.sh — swaylock wrapper with consistent Catppuccin Mocha styling.
# Bind this to Mod+Shift+L (or call from idle.sh) instead of raw swaylock,
# so the look stays defined in one place.
#
set -euo pipefail

exec swaylock \
  --image "" \
  --color 1e1e2e \
  --inside-color 1e1e2e \
  --ring-color 89b4fa \
  --line-color 1e1e2e \
  --text-color cdd6f4 \
  --inside-ver-color 89b4fa \
  --ring-ver-color 89b4fa \
  --key-hl-color a6e3a1 \
  --separator-color 1e1e2e \
  --font "JetBrainsMono Nerd Font" \
  --indicator-radius 100 \
  --indicator-thickness 10 \
  --fade-in 0.2
