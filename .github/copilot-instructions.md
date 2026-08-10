# Copilot instructions for cumulus.dotfiles

Personal Sway/Wayland desktop dotfiles (cloud-themed: aws/azure/gcp/oci) for
Ubuntu/Debian (apt) and Arch (pacman/AUR). Bash-first, plus one Python script
and zsh config. See `project-context.md` for the full rule set — it is
authoritative; this file is the quick orientation.

## Validate changes (no build system, no CI)

- Syntax: `bash -n <changed-script>`
- Tests: run a single test directly — `bash tests/palettes.sh` (each
  `tests/*.sh` is a standalone executable, `set -euo pipefail`, exits non-zero
  on the first `FAIL:` line). There is no runner/harness beyond `set -e`.
- Sway config: `sway --validate -c "$HOME/.config/sway/config"`
- Whole-setup health check: `./scripts/validate.sh` (OK/WARN/FAIL, read-only,
  non-zero exit on any FAIL)
- Installer flows: `./install.sh --dry-run --all-tools` (previews with zero
  side effects; `--dry-run` is forwarded to every installer)

## Big-picture architecture

The repo *is* the source of truth — files are **symlinked** into `$HOME`, never
copied. Two spines:

- **Deploy** (`install.sh`): the `LINKS` map + `link_one()`/`link_scripts()`
  symlink configs into `$HOME` and every `scripts/*.{sh,py}` into
  `~/.local/bin/cumulus-<name>`. Idempotent; real files are backed up to
  `~/.cumulus_backup/<ts>/` before linking. `bootstrap.sh` is the remote
  clone-then-`install.sh` entry point.
- **Theme engine** (`scripts/theme.sh`): the pipeline is
  `generate_configs` (render `themes/palettes/<flavor>.sh` + `config/{waybar,wofi}/*.css.tmpl`)
  → `publish_configs` (all-or-nothing swap with rollback)
  → `write_state` (`~/.config/cumulus/theme/state`)
  → `reload_apps` (`scripts/runtime-refresh.sh`, best-effort per-app adapters).
  Generated outputs (`config/{sway,kitty}/colors.conf`,
  `config/{waybar,wofi}/style.css`) are **gitignored derived artifacts**.

Tracing a theme change or adding a flavor requires reading `theme.sh`, a
palette file, the templates, and `runtime-refresh.sh` together.

## Conventions that will bite you if missed

- **Never hand-edit generated configs** (`colors.conf`, `style.css`). Edit the
  palette (`themes/palettes/*.sh`) or template (`*.css.tmpl`), then run
  `scripts/theme.sh apply`.
- **Palette variable changes touch three files together**: `validate_palette()`
  in `scripts/theme.sh`, the `required` list in `tests/palettes.sh`, and all
  four `themes/palettes/*.sh`. A partial update fails opaquely at runtime.
  Every palette defines `THEME_NAME` (= filename), `THEME_LABEL`,
  `NVIM_COLORSCHEME`, and 24 `#rrggbb` vars.
- **Waybar/wofi CSS is rendered via `sed` `@@PLACEHOLDER@@` substitution**, not
  GTK `@import` (which resolves relative to the process CWD and breaks).
- **Resolve the script's real path first**: `SELF="$(readlink -f "${BASH_SOURCE[0]}")"`
  then derive `DOTFILES_DIR` — scripts run through `cumulus-*` symlinks, so
  `$0`/relative paths won't find the repo.
- **Theme state is written only via `write_state()`** (atomic mktemp+`mv -f`,
  rejects embedded newlines); reads must tolerate a missing file. Default when
  no state exists is `oci` / `rotate` (not `aws`, despite the branding).
- **Bash mode is `set -euo pipefail`** except documented exceptions — don't
  "fix" them: `validate.sh` uses `-uo` (must keep running past failed checks);
  `install-sdkman.sh` omits `-u` (sourcing `sdkman-init.sh` needs unset vars).
- **Installers**: idempotent, detect `apt` before `pacman`, AUR via `yay` then
  `paru` (warn if neither), and must accept `--dry-run` (route side effects
  through the `run()` convention). Each script owns its own colored
  `log()`/`die()` helpers — there is no shared logging library.
- **Account operations** (AD/LDAP/SSSD hosts): try the normal command, fall
  back to NSS-aware `sudo usermod`, then warn — never abort.
- Script header `#` comments are the `--help`/`-h` output (`grep '^#' "$0"`);
  keep them accurate.
- Legacy Catppuccin flavor names (`mocha`/`macchiato`/`frappe`/`latte`) were
  renamed to `aws`/`azure`/`gcp`/`oci` — don't reintroduce them.
