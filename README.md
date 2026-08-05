# dotfiles

Personal Sway/Wayland desktop configuration — Catppuccin Mocha theme, native
Sway keybindings, wofi launcher, waybar status bar, kitty terminal, and zsh
shell config. Built to be cloned onto a fresh Ubuntu or Arch machine and
fully working within a couple of commands.

## Contents

```
install.sh                       # deploys everything below via symlinks
zsh/.zshrc                        # thin oh-my-zsh bootstrap + modular config loader
zsh/zsh_config/                   # actual zsh config, one *.zsh file per concern (see below)
config/sway/config                # Sway window manager config (stock keybindings + which-key)
config/sway/scripts/whichkey.sh   # parses config live, shows a searchable keybinding cheatsheet
config/wofi/                      # app launcher (Mod+D) look & behavior
config/waybar/                    # status bar config/style
config/kitty/                     # terminal emulator config
scripts/                          # standalone automations, symlinked onto $PATH (see below)
```

## How it works

This repo *is* the source of truth — nothing is copied into `$HOME`, it's
**symlinked**:

```
~/.zshrc                          -> ~/dotfiles/zsh/.zshrc
~/.config/dotfiles/zsh_config      -> ~/dotfiles/zsh/zsh_config
~/.config/sway                    -> ~/dotfiles/config/sway
~/.config/wofi                    -> ~/dotfiles/config/wofi
~/.config/waybar                  -> ~/dotfiles/config/waybar
~/.config/kitty                   -> ~/dotfiles/config/kitty
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

Once configs are symlinked, you can also run any of the `scripts/install-*.sh`
tool installers straight from `install.sh` — no need to invoke them by hand:

```bash
./install.sh --zsh        # zsh + oh-my-zsh + Nerd Font + nvim as default editor
./install.sh --nvim       # latest Neovim + full plugin toolchain
./install.sh --apps       # default desktop applications (browsers, IDEs, chat, etc.)
./install.sh --devops     # Docker + Terraform + Ansible
./install.sh --all-tools  # auto-discovers and runs every scripts/install-*.sh
```

`--dry-run` is forwarded to whichever installer(s) you select, so
`./install.sh --dry-run --all-tools` previews everything end-to-end with no
changes made.

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
| `Mod+Shift+L` | Lock screen now (`scripts/lock.sh`) |
| `Print` | Screenshot — full screen |
| `Mod+Print` | Screenshot — select a region |
| `Mod+Shift+Print` | Screenshot — focused window |

These are the stock Sway default bindings (reset from an earlier
ML4W-inspired custom set) with a few additions: the which-key cheatsheet,
manual lock, and screenshots.

## Zsh setup

`zsh/.zshrc` is intentionally thin — it just bootstraps
[oh-my-zsh](https://ohmyz.sh/) with the **Cloud** theme (`ZSH_THEME="cloud"`)
and then sources every `*.zsh` file it finds in
`~/.config/dotfiles/zsh_config/` (symlinked from `zsh/zsh_config/` in this
repo), in alphabetical/numeric order:

```
zsh_config/00-history.zsh               # HISTFILE, HISTSIZE, dedup/share options
zsh_config/10-completion-keybindings.zsh # completion menu/matcher, emacs keybindings
zsh_config/20-ssh-agent.zsh             # reuse one ssh-agent across shells
zsh_config/30-aliases-general.zsh       # ll/la/l, .., grep, vim->nvim, reload
zsh_config/31-aliases-git.zsh           # g/gs/ga/gc/gp/gl/...
zsh_config/32-aliases-docker.zsh        # d/dc/dps/dexec/...
zsh_config/33-aliases-k8s.zsh           # k/kgp/kaf/kctx/...
zsh_config/34-aliases-tmux.zsh          # t/ta/tn/tls
zsh_config/40-environment.zsh           # EDITOR/VISUAL=nvim, PATH, Wayland hints
zsh_config/90-nvm.zsh                   # loads NVM if installed
zsh_config/99-sdkman-cargo.zsh          # SDKMAN + cargo — MUST stay last
```

**Adding your own config:** just drop a new file in
`~/.config/dotfiles/zsh_config/` (e.g. `50-work-stuff.zsh`) — it's
auto-sourced on the next shell start, no need to edit `.zshrc` itself. Since
that directory is a symlink into this repo, anything you add there is
already tracked by git. Keep new files numbered below `99-` so SDKMAN still
loads last (its init script requires that).

Run `dotfiles-install-zsh` (see below) to install zsh + oh-my-zsh, the Cloud
theme's requirements, JetBrainsMono Nerd Font, and set Neovim as the
default editor — then `./install.sh` to symlink `.zshrc`/`zsh_config/` into
place.

## Scripts & automation

Everything in `scripts/` is symlinked by `install.sh` into
`~/.local/bin/dotfiles-<name>` (stripping the `.sh`), so each is callable as
a plain command from anywhere once `~/.local/bin` is on `$PATH` (already set
up in `zsh_config/40-environment.zsh`).

| Command | What it does |
|---|---|
| `dotfiles-update` | `git pull --ff-only` + re-run `install.sh` in this repo. Refuses to run if you have uncommitted local changes. Pass `--packages` to also refresh packages. |
| `dotfiles-backup` | Tars up all dotfiles-managed files/dirs from `$HOME` into `~/dotfiles-backups/<timestamp>.tar.gz` — a snapshot independent of git history. `--list` shows existing snapshots. |
| `dotfiles-restore [archive]` | Restores a `dotfiles-backup` snapshot (defaults to the most recent). Asks for confirmation and saves whatever's currently in place to `~/.dotfiles_backup/pre-restore_<timestamp>/` first. |
| `dotfiles-screenshot {full\|region\|window}` | grim+slurp screenshot helper — saves to `~/Pictures/Screenshots` and copies to clipboard. Bound to `Print` / `Mod+Print` / `Mod+Shift+Print`. |
| `dotfiles-lock` | swaylock wrapper with the repo's Catppuccin Mocha styling baked in, so idle/manual/sleep locks always look the same. Bound to `Mod+Shift+L`. |
| `dotfiles-idle` | swayidle daemon (lock after 5 min, screens off after 10 min, suspend after 15 min, lock before sleep). Auto-started by `config/sway/config` on login — not usually run manually. |
| `dotfiles-install-apps` | Installs the "default applications" this desktop is built around (Ubuntu apt + snap only — see script header for Arch/AUR notes): Microsoft Edge, VS Code, GitHub CLI, Docker, Thunderbird, nm-applet, swaync, polkit, plus Firefox/1Password/IntelliJ IDEA/Obsidian/Telegram via snap, and `spotify_player` via cargo. `--dry-run` supported. |
| `dotfiles-install-nvim-deps` | Installs the latest Neovim (from upstream release tarball) and its full toolchain: luarocks, ImageMagick, mermaid-cli, Python/pip/pipx, nvm + latest Node/npm, tree-sitter-cli, ripgrep + fd, lazygit, lazydocker. Works on both apt and pacman. `telescope.nvim` itself is a plugin managed by the nvim config's lazy.nvim — this script only ensures its runtime deps (ripgrep/fd) are present. `--dry-run` supported. |
| `dotfiles-install-zsh` | Installs zsh + oh-my-zsh (unattended, `KEEP_ZSHRC=yes` so it never touches this repo's `.zshrc`), sets zsh as the default login shell, installs JetBrainsMono Nerd Font, and sets Neovim as the default editor (`git config --global core.editor`, plus `update-alternatives` on apt systems). Works on both apt and pacman. `--dry-run` supported. |
| `dotfiles-install-devops` | Installs the main DevOps toolchain: Docker (Engine, CLI, containerd, buildx, compose plugin) via Docker's official apt/pacman repo, Terraform via HashiCorp's official apt repo (or pacman's `terraform` package on Arch), and Ansible via apt/pacman. Also adds you to the `docker` group. Idempotent — skips anything already installed. Works on both apt and pacman. `--dry-run` supported. |

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
