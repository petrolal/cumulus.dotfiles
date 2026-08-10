# cumulus.dotfiles — Architecture (Executive Summary)

**What it is** — A personal, reproducible Sway/Wayland desktop config
(cloud-themed: AWS/Azure/GCP/OCI) that turns a fresh Ubuntu/Debian or Arch
machine into a fully-themed desktop in one command. Not an app — a
**symlink-based config system** where the repo *is* the source of truth.

**Stack** — 100% Rust (`cumulus-dotfiles` crate with multi-call binaries), Zsh/oh-my-zsh,
Sway + wofi/waybar/kitty, Neovim, SDKMAN, Docker/Terraform/Ansible; apt +
pacman/AUR; versions intentionally unpinned.

**Architecture** — Two spines:

- **Deploy** (`cumulus-install`, idempotent): pure Rust engine that symlinks configs into `$HOME`
  (backing up any real files to `~/.cumulus_backup/<ts>/` first) and compiles/links multi-call binaries to
  `~/.local/bin/cumulus-*`, installs packages/fonts/tools, then runs
  `cumulus-validate`.
- **Theme engine** (`cumulus-theme`, pure Rust in `src/theme/`): renders
  `themes/palettes/*.conf` + `.tmpl` templates → generated configs →
  publishes all-or-nothing (with rollback) → persists state → live-reloads
  apps via `cumulus-runtime-refresh` adapters.

```
palettes/*.conf + *.css.tmpl → cumulus theme → generated configs
   → cumulus-runtime-refresh (sway/waybar/kitty/wofi/nvim/os-gtk/rgb)
   → ~/.config/cumulus/theme/state
```

**Key invariants**

- Symlink-only (never copy into `$HOME`).
- Generated configs are derived — edit palette/template, not the output.
- Palette contract = 24 fixed `#rrggbb` vars + metadata (`THEME_NAME` must
  match filename).
- Atomic, newline-safe state writes (`~/.config/cumulus/theme/state`); missing state
  tolerated.
- Defaults = `oci` flavor / `rotate` mode.
- Installers are idempotent, apt-before-pacman, and `--dry-run`-capable.

**Interfaces**

- `cumulus theme {set,apply,next,list,current}`
- `cumulus install` flags (`--links-only`, `--all-tools`, `--dry-run`,
  `--no-packages`, `--no-nvim`, `--no-sdkman`, `--zsh/--apps/--devops/--browser`, …)
- `cumulus <command>` / `cumulus-*` commands (`update`, `validate`, `backup`, `restore`,
  `sdd`, `screenshot`, `lock`, `idle`, `autotiling`, `theme-picker`, `whichkey`, `install-*`)
- Sway keybindings (`$mod` = Super)

**Data model** — `~/.config/cumulus/theme/state`
(`FLAVOR/MODE/WALLPAPER/WALLPAPER_SOURCE/INTERVAL/NVIM_COLORSCHEME`), palette
files (`themes/palettes/*.conf`), the `themes/wallpapers/<flavor>(.|_|-)*` pool, and a
`systemd --user` wallpaper-rotation timer.

**Use cases** — Fresh-machine bootstrap via `bootstrap.sh`, `cumulus update` re-sync, theme
switching (CLI or `Mod+Shift+T` GUI picker), add flavor/config by drop-in,
backup/restore, cross-distro (apt/pacman) install.

**Testing & QA** — 100% Cargo integration & unit test suite in `tests/` exercising real behavior in temporary sandboxes. Lints & formatting via `cargo clippy --all-targets` and `cargo fmt`. Manual Sway check: `sway --validate -c ~/.config/sway/config`.

