---
project_name: 'cumulus.dotfiles'
user_name: 'Petrolal'
date: '2026-08-08'
sections_completed:
  ['technology_stack', 'language_rules', 'framework_rules', 'testing_rules', 'quality_rules', 'workflow_rules', 'anti_patterns']
status: 'complete'
rule_count: 28
existing_patterns_found: 9
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Version Policy

- Bash for installation, validation, backup/restore, theming, and desktop automation scripts, plus one Python 3 script (`scripts/autotiling.py`). Most scripts use `set -euo pipefail`; scripts that intentionally continue after failed optional checks may use a narrower mode, e.g. `set -uo pipefail` in `scripts/validate.sh`. `scripts/install-sdkman.sh` uses `set -o pipefail` with **no** `-u`, because `sdkman-init.sh` references unset variables internally — nounset mode breaks sourcing it; don't "fix" this to match the standard convention.
- Zsh with oh-my-zsh and the Cloud theme for the interactive shell; SDKMAN-managed JVM toolchain (Java/Kotlin/Maven/Gradle) installed via `scripts/install-sdkman.sh` and sourced at shell startup from `zsh/zsh_config/99-sdkman-cargo.zsh`.
- Sway/Wayland compositor, wofi launcher, waybar status bar, kitty terminal, swaylock/swayidle, grim/slurp/wl-clipboard.
- Cloud-provider palettes — `aws`, `azure`, `gcp`, `oci` (renamed from the earlier Catppuccin mocha/macchiato/frappe/latte flavors) — rendered by `scripts/theme.sh`. Default flavor when no state exists is `oci`.
- Hardware RGB lighting (OpenRGB/asusctl/liquidctl) synced to the active theme color via `scripts/rgb-theme.sh`.
- Ubuntu 24.04/Debian via `apt` and Arch Linux via `pacman`, with AUR support (`yay` then `paru`) for Arch-only packages; these targets and the package matrix are documented in `README.md` and `install.sh`.
- Neovim from the latest upstream release and its lazy.nvim/tooling ecosystem; Node/npm are managed through nvm where needed. The repository intentionally does not pin application or package versions; use the distro/upstream versions available for the target machine — this applies equally to the newer SDKMAN/RGB/AUR tooling.
- JetBrainsMono Nerd Font is installed from the upstream Nerd Fonts release by `scripts/install-fonts.sh`.

## Implementation Patterns

9 patterns observed directly in source (formerly cross-referenced against `docs/architecture.md`/`docs/development-guide.md`, which are currently deleted from the working tree — don't cite those paths until/unless they're restored):

1. Repo files are the source of truth and are symlinked into `$HOME` by `install.sh`.
2. `install.sh` is idempotent and backs up existing real files before replacing them.
3. Every `scripts/*.sh` file is exposed as `cumulus-<name>` on `$PATH`.
4. Installer scripts support apt and pacman where applicable, are idempotent, and accept `--dry-run`.
5. Scripts invoked through symlinks resolve their real location with `readlink -f` before locating repository files.
6. Theme-generated files are derived artifacts; edit palette files/templates, never generated output.
7. Sway-aware tools prefer the compositor's live resolved config via `swaymsg -t get_config`, with a file fallback outside Sway.
8. Account-management commands use try/fallback/warn behavior for AD/LDAP/SSSD accounts.
9. Hardware integrations (e.g. `rgb-theme.sh`) read the same `~/.config/cumulus/theme/state` file `theme.sh` writes, rather than maintaining separate state — new theme-aware tools should follow this pattern instead of inventing their own state.

## Critical Implementation Rules

### Language-Specific Rules (Bash)

- Use `set -euo pipefail` for new Bash scripts unless an expected nonzero result requires a documented narrower mode (e.g. `validate.sh` needs `-uo pipefail` to keep running after individual check failures; `install-sdkman.sh` omits `-u` because `sdkman-init.sh` references unset variables internally). Don't "fix" a documented exception to match the default.
- Resolve `SELF="$(readlink -f "${BASH_SOURCE[0]}")"` before deriving `DOTFILES_DIR`; scripts run through `~/.local/bin/cumulus-<name>` symlinks, so `$0`/relative paths won't resolve to the repo directly.
- Shared runtime state (theme flavor/mode, etc.) lives in `~/.config/cumulus/theme/state` as `KEY=value` lines. Write it atomically (`mktemp` in the same dir, then `mv -f`) — never edit in place — and reject values containing embedded newlines/carriage returns before persisting. Reading code must tolerate a missing state file.
- Each script owns its own `log()`/`die()` helpers with an ANSI-colored `[scriptname]` prefix; there's no shared logging library — keep new scripts consistent with that per-script pattern.
- Keep scripts safe to rerun. Add `--dry-run` to installers and route side effects through the existing `run()` convention.

### Framework-Specific Rules (Theme System)

- Never hand-edit `config/sway/colors.conf`, `config/kitty/colors.conf`, `config/waybar/style.css`, or `config/wofi/style.css`; they're generated from `themes/palettes/*.sh` + the `.tmpl` templates. Edit the palette/template, then run `scripts/theme.sh apply`.
- Palettes live in `themes/palettes/{aws,azure,gcp,oci}.sh` (renamed from the old Catppuccin mocha/macchiato/frappe/latte flavors — nothing should reference the old names anymore). `validate_palette()` requires every palette to define `THEME_NAME` (must match its filename), `THEME_LABEL`, `NVIM_COLORSCHEME` (`^[A-Za-z0-9_.-]+$`), and a fixed set of `#rrggbb` color vars (`BASE`, `MANTLE`, `CRUST`, `TEXT`, `SUBTEXT1`, `SUBTEXT0`, `SURFACE0`, `SURFACE1`, `SURFACE2`, `OVERLAY0`, `BLUE`, `LAVENDER`, `SAPPHIRE`, `SKY`, `TEAL`, `GREEN`, `YELLOW`, `PEACH`, `MAROON`, `RED`, `MAUVE`, `PINK`, `FLAMINGO`, `ROSEWATER`) — a new palette must supply all of these, not a subset.
- Waybar/wofi styles are rendered via `sed` placeholder substitution (`@@BASE@@` etc.) into real `.css` files rather than consumed via GTK `@import`, because GTK CSS `@import` resolves relative to the consuming process's CWD, not the including file's location.
- `publish_configs` swaps all four generated files via backup-then-move with rollback on any failure — preserve that all-or-nothing behavior if you touch this path.
- Default flavor when no state exists is `oci`, not `aws` — despite the README calling this the "AWS Cloud" desktop. Both `theme.sh apply` and `rgb-theme.sh` fall back to `oci`.
- Wallpapers matching `themes/wallpapers/<flavor>(.|_|-)*` are that flavor's pool for `--rotate`/`--theme-default`; new wallpaper filenames must be prefixed with their flavor name to be picked up.

### Testing Rules

- No test framework — each `tests/<name>.sh` is a standalone executable script, `set -euo pipefail`, exits non-zero on first `FAIL: ...` printed to stderr. There's no runner/harness beyond `set -e`.
- Tests exercise real behavior, not mocks: they `source` real palette files and invoke the real `scripts/theme.sh` with `env HOME="$TMP_DIR/home"` to sandbox state, stubbing only true externals (e.g. a fake `systemctl` shim on `$PATH` in `tests/state-safety.sh`).
- Always use `mktemp -d` + `trap 'rm -rf "$TMP_DIR"' EXIT` for scratch space and an isolated `$HOME`; never touch the real `~/.config/cumulus`.
- `tests/palettes.sh` asserts the same metadata/color-var contract as `validate_palette()` in `scripts/theme.sh`. Any change to the required palette variable list must update `scripts/theme.sh`, `tests/palettes.sh`, and all four palette files together.

### Code Quality & Style Rules

- Preserve the symlink model: add managed sources under `config/` or `zsh/`, then update `install.sh` only when a new destination mapping is needed. Never write install logic that copies files into `$HOME` instead of symlinking.
- For package installation, detect `apt` before `pacman`, use noninteractive package commands, and fail clearly when neither is available. On Arch, check `yay` then `paru` for AUR-only packages; if neither exists, warn and leave AUR installation to the user rather than attempting it.
- Account-management operations must try the normal command first, fall back through NSS-aware `sudo usermod` where appropriate, and warn rather than abort when both paths fail (AD/LDAP/SSSD environments).
- Script header comments document `Usage:` and flags and are also the `--help`/`-h` output via `grep '^#' "$0"` — keep them accurate since they're user-facing help text, not just documentation.

### Development Workflow Rules

- Validate changes with `bash -n <changed-script>`, `./scripts/validate.sh` where the live desktop supports it, `sway --validate -c "$HOME/.config/sway/config"` for Sway changes, and `./install.sh --dry-run --all-tools` for installer-flow changes.
- Run `git diff --check` before committing. `themes/wallpapers/*.svg` and `themes/wallpapers/ATTRIBUTION.md` **are** tracked by design (default theme wallpapers) — only other/raster files under `themes/wallpapers/` are gitignored (personal wallpaper overrides). Generated theme config outputs (`config/{sway,kitty}/colors.conf`, `config/{waybar,wofi}/style.css`) remain gitignored.
- `scripts/__pycache__/` (from `autotiling.py`) is currently not gitignored — a pre-existing gap; don't silently commit `.pyc` files.
- No CI config exists yet, so pre-commit validation is manual — run the checks above for the area you touched rather than the full suite every time.

### Critical Don't-Miss Rules

- **Don't reference Catppuccin flavor names** (`mocha`/`macchiato`/`frappe`/`latte`) anywhere new — the theme system was fully renamed to cloud-provider palettes (`aws`/`azure`/`gcp`/`oci`). Old docs/branches may still mention them; treat that as stale, not as the current contract.
- **Don't add/remove a palette color variable without updating three places together**: `validate_palette()` in `scripts/theme.sh`, the required-vars list in `tests/palettes.sh`, and all four `themes/palettes/*.sh` files. A partial update passes nothing and fails opaquely at runtime.
- **Don't consume `.tmpl` files at runtime** for waybar/wofi — always render to the real `.css` via `theme.sh`, since GTK `@import` breaks depending on process CWD.
- **Don't write theme state directly** — always go through `write_state()`/`load_state()` in `theme.sh` (atomic write, newline validation) rather than `echo >>` or hand-editing `~/.config/cumulus/theme/state`.
- **Don't assume `docs/` or `_bmad-output/*` content is current** — those directories are currently empty in the working tree (deleted), even though some in-repo comments still reference `docs/architecture.md`/`docs/development-guide.md`. Verify against source before trusting a doc-file reference.

---

## Usage Guidelines

**For AI Agents:**

- Read this file before implementing any code in this repo.
- Follow ALL rules exactly as documented.
- When in doubt, prefer the more restrictive option.
- Update this file if new patterns emerge.

**For Humans:**

- Keep this file lean and focused on agent needs.
- Update when the technology stack or theme architecture changes (as it did with the Catppuccin → cloud-provider palette rename).
- Review periodically for outdated rules — the `docs/` deletion and stale doc-path references are a live example to watch for.

Last Updated: 2026-08-08

