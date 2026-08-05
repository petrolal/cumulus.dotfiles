# Project Overview

## cumulus.dotfiles — Personal Sway/Wayland Desktop Configuration

A single git repository that *is* the live configuration for a Sway/Wayland
desktop: window manager, launcher, status bar, terminal, shell, screen
locking/idle handling, a Catppuccin theme engine, and a set of installer
scripts that bootstrap a fresh Ubuntu or Arch machine to the same state in
a couple of commands.

## Purpose

Rebuilding a desktop environment from scratch (new machine, reinstall, or
migrating a coworker/friend onto the same setup) should not mean manually
re-copying config files and re-discovering "which packages did I need
again?". This repo turns that into: clone the repo, run `install.sh`, done
— and every config change made afterwards is automatically tracked by git
because the live config files *are* symlinks into this repo.

## Key Features

- **Symlink-based config management** — no copy/sync step; edit `~/.config/sway/config` and you've edited the tracked file directly.
- **Idempotent installer** (`install.sh`) — safe to re-run any time (e.g. after `git pull`); backs up pre-existing real files before linking over them, never deletes anything.
- **Directory-account aware** — `scripts/install-zsh.sh`'s default-shell step tries `chsh` then falls back to `sudo usermod -s`, so it still works (with a warning instead of a crash) on AD/LDAP/SSSD-joined machines where `chsh` fails against accounts that aren't in the local `/etc/passwd`.
- **Cross-distro package installation** — `--packages` flag auto-detects apt (Ubuntu) vs pacman (Arch) and installs the right package names; AUR fallback covers Arch-only packages with no official-repo equivalent (currently just Google Chrome).
- **Nerd Font installed unconditionally** (`scripts/install-fonts.sh`) — every `install.sh` run installs JetBrainsMono Nerd Font from the upstream GitHub release (same on apt/pacman, no distro package needed), since kitty/waybar/wofi/sway configs hardcode it; not gated behind `--zsh`/`--packages`.
- **Modular zsh config** — oh-my-zsh (Cloud theme) + numbered `*.zsh` files in `zsh_config/`, auto-sourced in order; drop in a new file to extend, no `.zshrc` edits needed.
- **Catppuccin theme engine** (`cumulus-theme`) — pick a flavor (mocha/macchiato/frappe/latte) and a background mode (flat color, static wallpaper, or timed rotation via a systemd `--user` timer), applied live and re-applied on every install.
- **Which-key cheatsheet** — `config/sway/scripts/whichkey.sh` fetches the *live, fully-resolved* config from the running compositor (`swaymsg -t get_config`, includes and `$var` substitutions already expanded) and shows every current keybinding in a searchable popup, so the keybinding docs can never drift out of sync with the actual config — even bindings defined in an `include`d file.
- **Tool installers** — dedicated `scripts/install-*.sh` for Neovim + full toolchain, default desktop apps, DevOps tooling (Docker/Terraform/Ansible), zsh/oh-my-zsh, and Google Chrome — each idempotent and `--dry-run`-able, auto-discovered by `install.sh --all-tools`.
- **Validation** — `cumulus-validate` (`scripts/validate.sh`) is a read-only sanity check across the whole setup (symlinks, `$PATH` commands, sway config validity, zsh/fonts, Neovim toolchain, DevOps tools), runs automatically at the end of every real `install.sh` invocation.
- **Backup/restore** — `cumulus-backup`/`cumulus-restore` snapshot everything this repo manages independently of git history (useful before risky experiments).

## Tech Stack Summary

| Category | Technology |
|---|---|
| Compositor / WM | Sway (i3-compatible, Wayland) |
| Launcher | wofi |
| Status bar | waybar |
| Terminal | kitty |
| Shell | zsh + oh-my-zsh (Cloud theme) |
| Screen lock / idle | swaylock + swayidle |
| Screenshots | grim + slurp + wl-clipboard |
| Theme system | Catppuccin palettes (Mocha/Macchiato/Frappé/Latte), rendered via `sed` templating |
| Wallpaper | swaybg (flat color / static image / systemd-timer-driven rotation) |
| Scripting | Bash (`set -euo pipefail`, consistent `log()`/`run()`/`--dry-run` conventions across all scripts) |
| Font | JetBrainsMono Nerd Font |
| Editor | Neovim (latest upstream release) + lazy.nvim plugin ecosystem, telescope/lazygit/lazydocker/tree-sitter toolchain |
| Package managers targeted | apt (Ubuntu/Debian), pacman + AUR (Arch) |
| Node/JS tooling | nvm-managed Node + npm (for Neovim tooling, mermaid-cli) |

## Architecture Type

**Symlink-based cumulus.dotfiles monorepo** with three cooperating layers:

1. **Config layer** (`config/`, `zsh/`) — the actual config files, tracked in git, symlinked into `$HOME`.
2. **Automation layer** (`scripts/`) — standalone Bash scripts, each symlinked onto `$PATH` as `cumulus-<name>`, covering installers, theming, backup/restore, screenshots, lock/idle, and validation.
3. **Theme layer** (`themes/`) — source-of-truth Catppuccin palettes + user-supplied wallpapers, rendered by `scripts/theme.sh` into generated (gitignored) config fragments consumed by layer 1's configs via native `include` directives (sway/kitty) or full template rendering (waybar/wofi, which need it due to GTK CSS's CWD-relative `@import` behavior).

## Repository Structure

```
cumulus.dotfiles/
├── install.sh              Idempotent entrypoint: symlink configs, install packages/tools, apply theme, validate
├── config/                 Sway, wofi, waybar, kitty configs (symlinked into ~/.config)
├── zsh/                    .zshrc + modular zsh_config/*.zsh (symlinked into $HOME / ~/.config/cumulus)
├── scripts/                Automations, symlinked onto $PATH as cumulus-<name>
├── themes/                 Catppuccin palettes (tracked) + wallpapers/ (user-supplied, gitignored)
├── docs/                   This documentation set
└── README.md                User-facing quick-start
```

## Status

- Sway/wofi/waybar/kitty/zsh baseline: **complete**, in daily use.
- Theme engine (flavors + flat/wallpaper/rotate): **complete**, tested end-to-end.
- Tool installers (Neovim, apps, DevOps, zsh, browser): **complete**.
- Validation + backup/restore: **complete**.
- This `docs/` set: **initial generation** — update alongside future architecture-level changes (new script categories, new theme mechanisms, new supported distros).
