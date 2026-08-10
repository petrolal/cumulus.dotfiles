# cumulus.dotfiles — Architecture (Executive Summary)

**What it is** — A personal, reproducible Sway/Wayland desktop config
(cloud-themed: AWS/Azure/GCP/OCI) that turns a fresh Ubuntu/Debian or Arch
machine into a fully-themed desktop in one command. Not an app — a
**symlink-based config system** where the repo *is* the source of truth.

**Stack** — Bash (+ one Python script, `autotiling.py`), Zsh/oh-my-zsh,
Sway + wofi/waybar/kitty, Neovim, SDKMAN, Docker/Terraform/Ansible; apt +
pacman/AUR; versions intentionally unpinned.

**Architecture** — Two spines:

- **Deploy** (`install.sh`, idempotent): symlink configs into `$HOME`
  (backing up any real files first) and `scripts/*` →
  `~/.local/bin/cumulus-*`, install packages/fonts/tools, then run
  `validate.sh`.
- **Theme engine** (`scripts/theme.sh`, the core): renders
  `themes/palettes/*.sh` + `.tmpl` templates → generated configs →
  publishes all-or-nothing (with rollback) → persists state → live-reloads
  apps via `scripts/runtime-refresh.sh` adapters.

```
palettes/*.sh + *.css.tmpl → theme.sh → generated configs
   → runtime-refresh.sh (sway/waybar/kitty/wofi/nvim/os-gtk/rgb)
   → ~/.config/cumulus/theme/state
```

**Key invariants**

- Symlink-only (never copy into `$HOME`).
- Generated configs are derived — edit palette/template, not the output.
- Palette contract = 24 fixed `#rrggbb` vars + metadata (`THEME_NAME` must
  match filename); changing the var set requires updating **3 files
  together**: `validate_palette()` in `theme.sh`, `tests/palettes.sh`, and
  all four `themes/palettes/*.sh`.
- Atomic, newline-safe state writes (mktemp + `mv -f`); missing state
  tolerated.
- Defaults = `oci` flavor / `rotate` mode.
- Installers are idempotent, apt-before-pacman, and `--dry-run`-capable.
- Scripts resolve `readlink -f` before deriving `DOTFILES_DIR` (they run via
  `cumulus-*` symlinks).

**Interfaces**

- `cumulus-theme {set,apply,next,list,current}`
- `install.sh` flags (`--links-only`, `--all-tools`, `--dry-run`,
  `--no-packages`, `--no-nvim`, `--no-sdkman`, `--zsh/--apps/--devops/--browser`, …)
- `cumulus-*` commands (`update`, `validate`, `backup`, `restore`,
  `screenshot`, `lock`, `idle`, `install-*`)
- Sway keybindings (`$mod` = Super)

**Data model** — `~/.config/cumulus/theme/state`
(`FLAVOR/MODE/WALLPAPER/WALLPAPER_SOURCE/INTERVAL/NVIM_COLORSCHEME`), palette
files, the `themes/wallpapers/<flavor>(.|_|-)*` pool, and a
`systemd --user` wallpaper-rotation timer.

**Use cases** — Fresh-machine bootstrap, `cumulus-update` re-sync, theme
switching (CLI or `Mod+Shift+T` GUI picker), add flavor/config by drop-in,
backup/restore, cross-distro (apt/pacman) install.

**Testing** — No framework; standalone sandboxed `tests/*.sh` scripts
(`set -euo pipefail`, non-zero on first `FAIL`) exercising real behavior.
Manual checks: `bash -n`, `sway --validate`, `./install.sh --dry-run
--all-tools`, `cumulus-validate`. No CI yet.
