# dotfiles — Project Documentation Index

> Generated: 2026-08-05 | Scan Level: Deep | Mode: Initial Scan (BMAD document-project pattern)

## Project Overview

- **Name:** dotfiles
- **Type:** Personal system-configuration monorepo (not a software product — no runtime/build/deploy pipeline)
- **Primary Languages:** Bash (scripts, install logic), Zsh (shell config), plain-text config DSLs (Sway, waybar/wofi GTK CSS, kitty.conf)
- **Architecture:** Symlink-based dotfiles repo + a small idempotent installer + a Catppuccin theme-rendering engine
- **License:** Personal use (no LICENSE file — not distributed as a product)

## Quick Reference

- **Target platforms:** Ubuntu 24.04 (apt) and Arch Linux (pacman/AUR) — Sway/Wayland desktop
- **Entry point:** `install.sh` (symlinks configs, installs the Nerd Font unconditionally, optionally installs packages/tools, applies theme, runs validation)
- **Core pattern:** every managed config lives as a real file *in this repo* and is **symlinked** into `$HOME`/`~/.config` — editing the live config *is* editing the tracked file
- **Automation:** `scripts/*.sh`, each auto-symlinked onto `$PATH` as `dotfiles-<name>`
- **Theming:** `scripts/theme.sh` (Catppuccin flavor + flat/wallpaper/rotate background), state in `~/.config/dotfiles/theme/state`

## Generated Documentation

- [Project Overview](./project-overview.md) — purpose, features, "tech stack" (tools/frameworks it manages and depends on)
- [Architecture](./architecture.md) — symlink model, installer flow, theme-rendering pipeline, script conventions
- [Source Tree Analysis](./source-tree-analysis.md) — annotated directory structure with why each folder exists
- [Component Inventory](./component-inventory.md) — every script, config, and generated artifact, what it does and how it's wired together
- [Development Guide](./development-guide.md) — how to add a config, add a script, add a theme flavor, test changes, and the conventions to follow

## Existing Documentation

- [README.md](../README.md) — the user-facing quick-start (install, keybindings, zsh setup, scripts, theming, updating). These `docs/` files go one level deeper: *why* things are structured this way and *how* to extend them safely, complementing rather than duplicating the README.

## Getting Started

```bash
git clone <this-repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh --packages    # symlink configs + install required packages
swaymsg reload              # or Mod+Shift+C inside Sway
source ~/.zshrc
```

See [README.md](../README.md) for the full install matrix (`--zsh`, `--nvim`, `--apps`, `--devops`, `--browser`, `--all-tools`) and [development-guide.md](./development-guide.md) for how to extend the repo.
