# dotfiles

Personal Sway/Wayland desktop configuration (Ubuntu 24.04) — Catppuccin Mocha
theme, native Sway keybindings, wofi launcher, waybar status bar, kitty
terminal, and zsh shell config.

## Contents

```
zsh/.zshrc            # main zsh config (history, aliases, prompt, NVM/SDKMAN/cargo)
zsh/.zshrc_custom      # sourced from .zshrc — pre-Sway custom config, kept separate
config/sway/config     # Sway window manager config (stock keybindings + which-key)
config/sway/scripts/    # helper scripts (e.g. whichkey.sh cheatsheet, Mod+Shift+/)
config/wofi/            # app launcher (Mod+D) look & behavior
config/waybar/          # status bar config/style
config/kitty/           # terminal emulator config
install.sh              # deploys everything above via symlinks
```

## Install

```bash
git clone <this-repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh              # symlink configs into $HOME (existing files are backed up)
./install.sh --packages    # also apt-install sway, wofi, waybar, kitty, etc. first
./install.sh --dry-run     # preview what would happen, no changes made
```

Any real (non-symlink) file/dir currently at a target location is moved to
`~/.dotfiles_backup/<timestamp>/` before the symlink is created, so nothing
is ever silently overwritten.

## After installing

```bash
swaymsg reload      # or Mod+Shift+C inside Sway
source ~/.zshrc
```

## Key bindings

Press `Mod+Shift+/` inside Sway for a searchable which-key style cheatsheet
of every binding currently active (parsed live from `config/sway/config`).
Press `Mod+D` for the app launcher (wofi drun).

## Updating

Edit files directly under `~/.config/...` or `~/.zshrc*` as usual — since
they're symlinks into this repo, changes are already tracked here. Just
`git add -A && git commit` from `~/dotfiles` when you want to save a
checkpoint, then push.
