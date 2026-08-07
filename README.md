# cumulus.dotfiles

Personal Sway/Wayland desktop configuration — AWS Cloud theme, native
Sway keybindings, wofi launcher, waybar status bar, kitty terminal, and zsh
shell config. Built to be cloned onto a fresh Ubuntu or Arch machine and
fully working within a couple of commands.

## Contents

```
bootstrap.sh                      # curl-able one-liner: clones/updates the repo, then runs install.sh
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
~/.zshrc                          -> ~/cumulus.dotfiles/zsh/.zshrc
~/.config/cumulus/zsh_config      -> ~/cumulus.dotfiles/zsh/zsh_config
~/.config/sway                    -> ~/cumulus.dotfiles/config/sway
~/.config/wofi                    -> ~/cumulus.dotfiles/config/wofi
~/.config/waybar                  -> ~/cumulus.dotfiles/config/waybar
~/.config/kitty                   -> ~/cumulus.dotfiles/config/kitty
```

So editing `~/.config/sway/config` directly *is* editing the file tracked in
this repo — no sync step needed. `install.sh` handles creating those links
safely:

1. If the target is already a symlink to the right repo file → skip (safe
   to re-run any time, e.g. after `git pull`).
2. If the target is a real file/dir → move it to
   `~/.cumulus_backup/<timestamp>/` first, then link. Nothing is ever
   deleted.
3. Optionally (`--packages`) installs every required package first.

## Quick Installation

On a brand-new machine, skip the manual clone — this one-liner fetches
`bootstrap.sh`, clones the repo to `~/cumulus.dotfiles` (or updates it if already
present), and hands off straight into `install.sh`:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/petrolal/cumulus.dotfiles/master/bootstrap.sh)
```

Flags are forwarded verbatim to `install.sh`, so a full fresh-machine setup
(packages + every tool installer) is one command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/petrolal/cumulus.dotfiles/master/bootstrap.sh) --packages --all-tools
```

Preview everything first with zero side effects:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/petrolal/cumulus.dotfiles/master/bootstrap.sh) --dry-run --all-tools
```

> Run this as your normal user, **not** root/sudo — it sets up your
> interactive desktop session (Sway/zsh/theme). `bootstrap.sh` refuses to
> run as root for this reason. See [Install](#install) below for the
> manual clone + flag reference.

## Install

```bash
git clone <this-repo-url> ~/cumulus.dotfiles
cd ~/cumulus.dotfiles
./install.sh              # default setup: install packages + symlink configs + deploy Cumulus Neovim
./install.sh --links-only # symlink configs only (skip package & tool installations)
./install.sh --dry-run     # preview what would happen, no changes made
```

Every run finishes with `scripts/validate.sh` (skip with `--no-validate`), so you
immediately see OK/WARN/FAIL for the whole setup instead of finding out something's
broken later.

`./install.sh` installs required desktop packages and Cumulus Neovim by default. You can also run any of the additional `scripts/install-*.sh`
tool installers straight from `install.sh`:

```bash
./install.sh --zsh         # zsh + oh-my-zsh + Nerd Font + nvim as default editor
./install.sh --no-packages # skip system apt/pacman package installation
./install.sh --no-nvim     # skip Neovim & cumulus.nvim deployment
./install.sh --apps        # default desktop applications (browsers, IDEs, chat, etc.)
./install.sh --devops      # Docker + Terraform + Ansible
./install.sh --browser     # Google Chrome + set as default browser
./install.sh --all-tools   # auto-discovers and runs every scripts/install-*.sh
```

`--dry-run` is forwarded to whichever installer(s) you select, so
`./install.sh --dry-run --all-tools` previews everything end-to-end with no
changes made.

`--packages` auto-detects your package manager:

- **Debian/Ubuntu (apt)** — installs:
  `sway wofi waybar kitty grim slurp wl-clipboard brightnessctl playerctl swaylock swayidle wdisplays blueman`
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
| `Mod+Shift+B` | Open Google Chrome |
| `Mod+Shift+F` | Open terminal file manager (yazi) |
| `Mod+Shift+/` | **Which-key cheatsheet** — searchable popup of every binding, parsed live from `config/sway/config` |
| `Mod+Shift+T` | **Theme picker** — wofi GUI to pick a cloud flavor + background mode (flat/wallpaper/rotate), front-end for `cumulus-theme` |
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
| `Mod+Escape` | Lock screen now (`scripts/lock.sh`) |
| `Mod+Shift+Escape` | Suspend system (`systemctl suspend`) |
| `Mod+Ctrl+Escape` | Shutdown system (`systemctl poweroff`) |
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
`~/.config/cumulus/zsh_config/` (symlinked from `zsh/zsh_config/` in this
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
`~/.config/cumulus/zsh_config/` (e.g. `50-work-stuff.zsh`) — it's
auto-sourced on the next shell start, no need to edit `.zshrc` itself. Since
that directory is a symlink into this repo, anything you add there is
already tracked by git. Keep new files numbered below `99-` so SDKMAN still
loads last (its init script requires that).

Run `cumulus-install-zsh` (see below) to install zsh + oh-my-zsh, the Cloud
theme's requirements, JetBrainsMono Nerd Font, and set Neovim as the
default editor — then `./install.sh` to symlink `.zshrc`/`zsh_config/` into
place.

## Scripts & automation

Everything in `scripts/` is symlinked by `install.sh` into
`~/.local/bin/cumulus-<name>` (stripping the `.sh`), so each is callable as
a plain command from anywhere once `~/.local/bin` is on `$PATH` (already set
up in `zsh_config/40-environment.zsh`).

| Command | What it does |
|---|---|
| `cumulus-update` | `git pull --ff-only` + re-run `install.sh` in this repo. Refuses to run if you have uncommitted local changes. Pass `--packages` to also refresh packages. |
| `cumulus-validate` | Read-only sanity check of the whole setup: symlinks, `cumulus-*` commands on `$PATH`, sway config validity, zsh/oh-my-zsh/Nerd Font, Neovim toolchain, and DevOps tools. Prints OK/WARN/FAIL per check and exits non-zero on any FAIL. Runs automatically at the end of `./install.sh` (skip with `--no-validate`); also safe to run anytime by hand. |
| `cumulus-backup` | Tars up all cumulus.dotfiles-managed files/dirs from `$HOME` into `~/cumulus-backups/<timestamp>.tar.gz` — a snapshot independent of git history. `--list` shows existing snapshots. |
| `cumulus-restore [archive]` | Restores a `cumulus-backup` snapshot (defaults to the most recent). Asks for confirmation and saves whatever's currently in place to `~/.cumulus_backup/pre-restore_<timestamp>/` first. |
| `cumulus-screenshot {full\|region\|window}` | grim+slurp screenshot helper — saves to `~/Pictures/Screenshots` and copies to clipboard. Bound to `Print` / `Mod+Print` / `Mod+Shift+Print`. |
| `cumulus-lock` | swaylock wrapper with the repo's AWS Cloud styling baked in, so idle/manual/sleep locks always look the same. Bound to `Mod+Escape`. |
| `cumulus-idle` | swayidle daemon (lock after 5 min, screens off after 10 min, suspend after 15 min, lock before sleep). Auto-started by `config/sway/config` on login — not usually run manually. |
| `cumulus-install-apps` | Installs the "default applications" this desktop is built around (Ubuntu apt + snap only — see script header for Arch/AUR notes): Microsoft Edge, VS Code, GitHub CLI, Docker, Thunderbird, nm-applet, blueman-applet, swaync, polkit, plus Firefox/1Password/IntelliJ IDEA/Obsidian/Telegram/Yazi via snap, and `spotify_player` via cargo. `--dry-run` supported. |
| `cumulus-install-nvim-deps` | Installs the latest Neovim (from upstream release tarball) and its full toolchain: luarocks, ImageMagick, mermaid-cli, Python/pip/pipx, nvm + latest Node/npm, tree-sitter-cli, ripgrep + fd, lazygit, lazydocker. Works on both apt and pacman. `telescope.nvim` itself is a plugin managed by the nvim config's lazy.nvim — this script only ensures its runtime deps (ripgrep/fd) are present. `--dry-run` supported. |
| `cumulus-install-zsh` | Installs zsh + oh-my-zsh (unattended, `KEEP_ZSHRC=yes` so it never touches this repo's `.zshrc`), sets zsh as the default login shell, installs JetBrainsMono Nerd Font, and sets Neovim as the default editor (`git config --global core.editor`, plus `update-alternatives` on apt systems). Works on both apt and pacman. `--dry-run` supported. |
| `cumulus-install-devops` | Installs the main DevOps toolchain: Docker (Engine, CLI, containerd, buildx, compose plugin) via Docker's official apt/pacman repo, Terraform via HashiCorp's official apt repo (or pacman's `terraform` package on Arch), and Ansible via apt/pacman. Also adds you to the `docker` group. Idempotent — skips anything already installed. Works on both apt and pacman. `--dry-run` supported. |
| `cumulus-install-browser` | Installs Google Chrome (official `.deb` on apt, which self-registers Google's repo for future updates; via `yay`/`paru` on Arch since it's AUR-only) and sets it as the default browser (`xdg-settings` + `xdg-mime` for http/https/html). Bound to `Mod+Shift+B`. Idempotent. `--dry-run` supported. |

## Theming

Colors and background come from `cumulus-theme` (`scripts/theme.sh`), which
renders the cloud flavor + background mode you pick into the actual
sway/kitty/waybar/wofi configs. The default is **aws, flat color** (no
wallpaper). State is saved to `~/.config/cumulus/theme/state` and
re-applied automatically every time you run `./install.sh`.

Flavors: `aws` (dark), `azure` (dark), `gcp` (dark), `oci` (dark).

```sh
cumulus-theme list                              # show flavors + wallpapers found
cumulus-theme current                           # show what's active now

cumulus-theme set aws                           # flat color background (default mode)
cumulus-theme set azure --wallpaper beach.jpg    # static wallpaper (path or bare filename
                                                   # resolved against themes/wallpapers/)
cumulus-theme set gcp --rotate --interval 30m    # rotate through every image in
                                                   # themes/wallpapers/ every 30 minutes

cumulus-theme apply                             # re-apply the saved theme (used by install.sh)
cumulus-theme next                              # manually advance rotation by one image
```

Drop any `.jpg`/`.jpeg`/`.png`/`.webp` files into `themes/wallpapers/` (not
tracked by git — add your own) to make them available to `--wallpaper`/
`--rotate`. Rotation is driven by a `systemd --user` timer
(`cumulus-wallpaper-rotate.timer`/`.service`), so it survives reboots and
is automatically disabled when you switch back to flat/static modes.

Switching themes reloads sway (`swaymsg reload`) so client borders, the
background, and the waybar/wofi stylesheets pick up the new colors
immediately — no logout required.

Prefer a GUI? Press `Mod+Shift+T` to open the **theme picker**
(`config/sway/scripts/theme-picker.sh`) — a wofi-driven walkthrough
(flavor → flat/wallpaper/rotate → wallpaper file or interval) that calls
`cumulus-theme set` for you and shows a desktop notification when done.
It's a thin front-end only; all validation/state/reload logic still lives
in `theme.sh`.

Adding a new flavor: drop a `themes/palettes/<name>.sh` file defining the
same ~26 `BASE`/`TEXT`/`SURFACE0`/`BLUE`/... variables as the existing
palettes, and it's picked up automatically by `cumulus-theme list`/`set`
and by the theme picker.

## Updating

Edit files directly under `~/.config/...` or `~/.zshrc*` as usual — since
they're symlinks into this repo, changes are already tracked here. From
`~/cumulus.dotfiles`:

```bash
git add -A
git commit -m "describe the change"
git push
```

On another machine, just `git pull` inside `~/cumulus.dotfiles` and re-run
`./install.sh` (idempotent — only touches links that changed).
