# Copilot instructions for cumulus.dotfiles

Personal Sway/Wayland desktop dotfiles (cloud-themed: aws/azure/gcp/oci) for
Ubuntu/Debian (apt) and Arch (pacman/AUR). 100% Rust tooling crate (`cumulus-dotfiles`), plus
zsh config. This file is the authoritative rule set for agents working in
this repo; `docs/architecture.md` has the big-picture overview.

## Validate changes

- Rust crate tests: `cargo test` (at repo root)
- Lints & formatting: `cargo clippy --all-targets` and `cargo fmt`
- Sway config: `sway --validate -c "$HOME/.config/sway/config"`
- Whole-setup health check: `cumulus validate` (OK/WARN/FAIL, read-only, non-zero exit on any FAIL)
- Installer flows: `cumulus install --dry-run --all-tools` (previews with zero side effects; `--dry-run` is forwarded to every installer)

## Big-picture architecture

The repo *is* the source of truth — files are **symlinked** into `$HOME`, never
copied. Two spines:

- **Deploy** (`cumulus-install`): symlink configs into `$HOME` and binary suite into `~/.local/bin/cumulus-*`. Idempotent; real files are backed up to `~/.cumulus_backup/<ts>/` before linking. `bootstrap.sh` is the remote one-liner bootstrapper.
- **Theme engine** (`cumulus-theme`): renders palettes (`themes/palettes/<flavor>.conf` + `config/{waybar,wofi}/*.css.tmpl`) → atomic swap with rollback → state (`~/.config/cumulus/theme/state`) → `cumulus-runtime-refresh`. Generated outputs (`colors.conf`, `style.css`) are **gitignored derived artifacts**.

## Conventions that will bite you if missed

- **Never hand-edit generated configs** (`colors.conf`, `style.css`). Edit the palette (`themes/palettes/*.conf`) or template (`*.css.tmpl`), then run `cumulus theme apply`.
- **Palette variable changes touch palettes together**: every `.conf` palette defines `THEME_NAME`, `THEME_LABEL`, `NVIM_COLORSCHEME`, and 24 `#rrggbb` color vars.
- **Theme state is written atomically**; reads must tolerate a missing file. Default when no state exists is `oci` / `rotate`.
- **Installers**: idempotent, detect `apt` before `pacman`, AUR via `yay` then `paru` (warn if neither), and must accept `--dry-run`.
- Legacy Catppuccin flavor names (`mocha`/`macchiato`/`frappe`/`latte`) were renamed to `aws`/`azure`/`gcp`/`oci` — don't reintroduce them.

