---
project_name: 'cumulus.dotfiles'
user_name: 'luhenr'
date: '2026-08-05'
sections_completed: ['technology_stack', 'implementation_rules']
existing_patterns_found: 8
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Version Policy

- Bash for installation, validation, backup/restore, theming, and desktop automation scripts. Most scripts use `set -euo pipefail`; scripts that intentionally continue after failed optional checks may use a narrower mode, such as `set -uo pipefail` in `scripts/validate.sh`.
- Zsh with oh-my-zsh and the Cloud theme for the interactive shell.
- Sway/Wayland compositor, wofi launcher, waybar status bar, kitty terminal, swaylock/swayidle, grim/slurp/wl-clipboard.
- Catppuccin palettes (mocha, macchiato, frappe, latte), rendered by `scripts/theme.sh`.
- Ubuntu 24.04/Debian via `apt` and Arch Linux via `pacman`; these targets and the package matrix are documented in `README.md`, `docs/project-overview.md`, and `install.sh`.
- Neovim from the latest upstream release and its lazy.nvim/tooling ecosystem; Node/npm are managed through nvm where needed. The repository intentionally does not pin application or package versions; use the distro/upstream versions available for the target machine.
- JetBrainsMono Nerd Font is installed from the upstream Nerd Fonts release by `scripts/install-fonts.sh`.

## Implementation Patterns

The eight discovered patterns are documented in `docs/architecture.md`, `docs/development-guide.md`, and the referenced source files:

1. Repo files are the source of truth and are symlinked into `$HOME` by `install.sh`.
2. `install.sh` is idempotent and backs up existing real files before replacing them.
3. Every `scripts/*.sh` file is exposed as `cumulus-<name>` on `$PATH`.
4. Installer scripts support apt and pacman where applicable, are idempotent, and accept `--dry-run`.
5. Scripts invoked through symlinks resolve their real location with `readlink -f` before locating repository files.
6. Theme-generated files are derived artifacts; edit palette files/templates, never generated output.
7. Sway-aware tools prefer the compositor’s live resolved config via `swaymsg -t get_config`, with a file fallback outside Sway.
8. Account-management commands use try/fallback/warn behavior for AD/LDAP/SSSD accounts.

## Critical Implementation Rules

- Use `set -euo pipefail` for new Bash scripts unless an expected nonzero result requires a documented narrower mode. Handle optional failures explicitly instead of masking unexpected errors.
- Keep scripts safe to rerun. Add `--dry-run` to installers and route side effects through the existing `run()` convention.
- Resolve `SELF` with `readlink -f "${BASH_SOURCE[0]}"` before deriving `DOTFILES_DIR`; direct symlink-relative paths resolve to `~/.local/bin`.
- Preserve the symlink model: add managed sources under `config/` or `zsh/`, then update `install.sh` only when a new destination mapping is needed.
- Never hand-edit `config/sway/colors.conf`, `config/kitty/colors.conf`, `config/waybar/style.css`, or `config/wofi/style.css`; update `themes/palettes/*.sh` or the corresponding `.tmpl` file and run `scripts/theme.sh`.
- Keep palette variables and generated config syntax compatible with all four Catppuccin flavors. Waybar and wofi styles must remain fully rendered because GTK CSS imports resolve relative to process CWD.
- For package installation, detect `apt` before `pacman`, use noninteractive package commands, and fail clearly when neither is available. On Arch, check `yay` then `paru`; if neither exists, warn and leave AUR-only installation to the user.
- Account-management operations must try the normal command, fall back through NSS-aware `sudo usermod` where appropriate, and warn rather than abort when both paths fail.
- Validate changes with `bash -n <changed-script>`, `./scripts/validate.sh` where the live desktop supports it, `sway --validate -c "$HOME/.config/sway/config"` for Sway changes, and `./install.sh --dry-run --all-tools` for installer-flow changes.
- Run `git diff --check` before committing. Generated theme outputs and `themes/wallpapers/` are intentionally gitignored.
