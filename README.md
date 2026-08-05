# dotfiles

Personal Sway/Wayland desktop configuration — Catppuccin Mocha theme, native
Sway keybindings, wofi launcher, waybar status bar, kitty terminal, and zsh
shell config. Built to be cloned onto a fresh Ubuntu or Arch machine and
fully working within a couple of commands.

## Contents

```
install.sh                       # deploys everything below via symlinks
zsh/.zshrc                       # main zsh config (history, aliases, prompt, NVM/SDKMAN/cargo)
zsh/.zshrc_custom                # sourced from .zshrc — kept separate for old/pre-Sway tweaks
config/sway/config                # Sway window manager config (stock keybindings + which-key)
config/sway/scripts/whichkey.sh   # parses config live, shows a searchable keybinding cheatsheet
config/wofi/                      # app launcher (Mod+D) look & behavior
config/waybar/                    # status bar config/style
config/kitty/                     # terminal emulator config
```

## How it works

This repo *is* the source of truth — nothing is copied into `$HOME`, it's
**symlinked**:

```
~/.zshrc              -> ~/dotfiles/zsh/.zshrc
~/.zshrc_custom        -> ~/dotfiles/zsh/.zshrc_custom
~/.config/sway         -> ~/dotfiles/config/sway
~/.config/wofi         -> ~/dotfiles/config/wofi
~/.config/waybar       -> ~/dotfiles/config/waybar
~/.config/kitty        -> ~/dotfiles/config/kitty
```

So editing `~/.config/sway/config` directly *is* editing the file tracked in
this repo — no sync step needed. `install.sh` handles creating those links
safely:

1. If the target is already a symlink to the right repo file → skip (safe
   to re-run any time, e.g. after `git pull`).
2. If the target is a real file/dir → move it to
   `~/.dotfiles_backup/<timestamp>/` first, then link. Nothing is ever
   deleted.
3. Optionally (`--packages`) installs every required package first.

## Install

```bash
git clone <this-repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh              # symlink configs into $HOME (existing files are backed up)
./install.sh --packages    # also install sway, wofi, waybar, kitty, etc. first
./install.sh --dry-run     # preview what would happen, no changes made
```

`--packages` auto-detects your package manager:

- **Debian/Ubuntu (apt)** — installs:
  `sway wofi waybar kitty grim slurp wl-clipboard brightnessctl playerctl swaylock swayidle`
- **Arch (pacman)** — installs the same list via `pacman -S --needed`, plus
  the Nerd Font (`ttf-jetbrains-mono-nerd`, used by wofi/waybar/kitty
  styling) via an AUR helper (`yay` or `paru`) if one is found on `$PATH`.
  If no AUR helper is installed, install one first:
  ```bash
  sudo pacman -S --needed base-devel git
  git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
  ```
  or grab the font manually afterwards.

> Note: `swaynag` isn't installed separately — it ships bundled with the
> `sway` package on both distros.

## After installing

```bash
swaymsg reload      # or Mod+Shift+C inside Sway
source ~/.zshrc      # or open a new terminal
```

## Key bindings

`$mod` = Mod4 (Super/Windows key). Full list also always available live via
the which-key cheatsheet below — this is just a quick reference.

| Keys | Action |
|---|---|
| `Mod+Return` | Open terminal (kitty) |
| `Mod+D` | App launcher (wofi drun — fuzzy search installed apps) |
| `Mod+Shift+/` | **Which-key cheatsheet** — searchable popup of every binding, parsed live from `config/sway/config` |
| `Mod+Shift+Q` | Kill focused window |
| `Mod+Shift+C` | Reload Sway config |
| `Mod+Shift+E` | Exit Sway session (with confirmation) |
| `Mod+h/j/k/l` or arrows | Move focus left/down/up/right |
| `Mod+Shift+h/j/k/l` or arrows | Move focused window left/down/up/right |
| `Mod+1..0` | Switch to workspace 1–10 |
| `Mod+Shift+1..0` | Move focused window to workspace 1–10 |
| `Mod+B` / `Mod+V` | Split horizontal / vertical |
| `Mod+S` / `Mod+W` / `Mod+E` | Layout: stacking / tabbed / toggle split |
| `Mod+F` | Fullscreen toggle |
| `Mod+Shift+Space` | Floating toggle |
| `Mod+Space` | Focus tiling ↔ floating |
| `Mod+A` | Focus parent container |
| `Mod+Minus` / `Mod+Shift+Minus` | Show / send to scratchpad |
| `Mod+R` | Enter resize mode (then h/j/k/l or arrows to resize, Return/Escape to exit) |

These are the stock Sway default bindings (reset from an earlier
ML4W-inspired custom set) with one addition: the which-key cheatsheet.

## Updating

Edit files directly under `~/.config/...` or `~/.zshrc*` as usual — since
they're symlinks into this repo, changes are already tracked here. From
`~/dotfiles`:

```bash
git add -A
git commit -m "describe the change"
git push
```

On another machine, just `git pull` inside `~/dotfiles` and re-run
`./install.sh` (idempotent — only touches links that changed).
