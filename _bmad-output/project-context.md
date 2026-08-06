---
project_name: 'cumulus.dotfiles'
user_name: 'Petrolal'
date: '2026-08-06'
sections_completed: ['technology_stack', 'language_rules', 'architecture_rules', 'testing_validation_rules']
status: 'complete'
rule_count: 19
optimized_for_llm: true
existing_patterns_found: 8
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Version Policy

- **Bash:** Primary language for installation, validation, backup/restore, theming, and desktop automation scripts. Uses `set -euo pipefail` by default (documented narrower modes allowed for specific scripts like `scripts/validate.sh`).
- **Zsh:** Interactive shell powered by oh-my-zsh and the Cloud theme.
- **Sway/Wayland Desktop Ecosystem:** Sway compositor, `wofi` launcher, `waybar` status bar, `kitty` terminal, `swaylock`/`swayidle`, `grim`/`slurp`/`wl-clipboard`.
- **Theming Engine:** Catppuccin color palettes (`mocha`, `macchiato`, `frappe`, `latte`) rendered by `scripts/theme.sh` from `.tmpl` templates.
- **Target OS Distributions:** Ubuntu 24.04 / Debian via `apt` and Arch Linux via `pacman`. Intentionally unpinned package versions—uses distro/upstream latest.
- **Editor & Fonts:** Neovim from latest upstream release with `lazy.nvim` ecosystem; Node/npm managed via `nvm`. JetBrainsMono Nerd Font installed directly from upstream GitHub release by `scripts/install-fonts.sh`.

## Critical Implementation Rules

### Language-Specific & Scripting Rules (Bash / Zsh)

- **Strict Mode Default:** Always use `set -euo pipefail` at the top of new scripts under `scripts/`. Narrower modes (e.g., `set -uo pipefail`) are permitted only when handling optional command failures explicitly and must be documented.
- **Symlink-Safe Self Location:** Because scripts are executed via `~/.local/bin/cumulus-*` symlinks, scripts resolving the repository root MUST use `SELF="$(readlink -f "${BASH_SOURCE[0]}")"` before calling `dirname "$SELF"`. Do NOT use `dirname "${BASH_SOURCE[0]}"` directly.
- **Idempotency & Safe Side Effects:** Route all mutating commands through the `run()` helper to support `--dry-run`. All installer and configuration scripts must be safe to re-run multiple times.
- **Self-Documenting Help Headers:** Top header comments starting with `#` double as `--help` output (parsed via `grep '^#' "$0" | sed 's/^#//'`). Keep top-of-file comments accurate and formatted.
- **NSS / AD / LDAP Fallback Protocol:** Account-management operations (such as `chsh`) must try standard commands first, fall back through `sudo usermod`, and warn gracefully rather than terminating the script under `set -e` when running on directory-backed accounts.

### Desktop & Templating Architecture Rules

- **Derived Output Immutability:** Never directly edit generated theme outputs (`config/sway/colors.conf`, `config/kitty/colors.conf`, `config/waybar/style.css`, `config/wofi/style.css`). Always edit `themes/palettes/*.sh` or corresponding `.tmpl` template files and run `scripts/theme.sh`.
- **GTK CSS Import Prohibition:** Do NOT use GTK CSS `@import` rules in Waybar or Wofi style sheets. GTK CSS imports resolve relative to process CWD, breaking when launched from arbitrary working directories in Sway. Waybar and Wofi styles must be rendered in full from `.tmpl` templates.
- **Dynamic Sway Config Resolution:** Tools reflecting Sway's active configuration (e.g. `whichkey.sh`) MUST prefer `swaymsg -t get_config` (in-memory expanded configuration) over reading `~/.config/sway/config` off disk, falling back to file reads only when outside a running Sway session.
- **Timer-Based Wallpaper Rotation:** Never write background `sleep` loops for wallpaper rotation. Use `systemd --user` units (`cumulus-wallpaper-rotate.timer`) managed via `theme.sh`.
- **Atomic State Persistence:** Write theme state changes (`~/.config/cumulus/theme/state`) via temporary files and atomic rename (`mv`) to prevent partial state reads.

### Testing, Validation & Multi-Distro Rules

- **Validation & Verification Protocol:** Validate script edits with `bash -n <script>`, run `git diff --check` before committing, check Sway configs with `sway --validate -c "$HOME/.config/sway/config"`, and run `./scripts/validate.sh` to test live desktop state.
- **Dry-Run Installer Verification:** Test installer changes end-to-end using `./install.sh --dry-run --all-tools`.
- **Multi-Distro Package Handling:** Package installer scripts MUST detect `apt` before `pacman` and execute non-interactive commands. For Arch AUR packages, check `yay` then `paru`; if neither exists, warn and leave AUR installation to the user rather than bootstrapping an AUR helper automatically.
- **Symlink Model Maintenance:** Add new managed configuration files under `config/` or `zsh/`. Only update `install.sh`'s `LINKS` array when adding a new top-level symlink target mapping.

---

## Usage Guidelines

**For AI Agents:**

- Read this file before implementing any code or modifying configurations in this project.
- Follow ALL rules exactly as documented.
- When in doubt, prefer the more restrictive/idempotent option.
- Update this file if new architecture patterns or implementation rules emerge.

**For Humans:**

- Keep this file lean and focused on AI agent needs.
- Update when technology stack or desktop components change.
- Review periodically to prune outdated rules.

Last Updated: 2026-08-06



