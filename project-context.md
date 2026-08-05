---
project_name: 'cumulus.dotfiles'
user_name: 'luhenr'
date: '2026-08-05'
sections_completed: ['technology_stack']
existing_patterns_found: 8
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

- Bash (`set -euo pipefail`) for installation, validation, backup/restore, theming, and desktop automation scripts.
- Zsh with oh-my-zsh and the Cloud theme for the interactive shell.
- Sway/Wayland compositor, wofi launcher, waybar status bar, kitty terminal, swaylock/swayidle, grim/slurp/wl-clipboard.
- Catppuccin palettes (mocha, macchiato, frappe, latte), rendered by `scripts/theme.sh`.
- Ubuntu/Debian via `apt` and Arch Linux via `pacman`; Arch-only packages may use `yay` or `paru`.
- Neovim and its lazy.nvim/tooling ecosystem; Node/npm are managed through nvm where needed.
- Generated documentation identifies Ubuntu 24.04 and Arch Linux as target platforms.

## Critical Implementation Rules

_Detailed rules will be generated collaboratively after confirmation._
