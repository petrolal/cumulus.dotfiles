# Architecture

## Executive Summary

This repo has no runtime process of its own — it's a **configuration
management system for a personal Sway desktop**, expressed as: (1) real
config files tracked in git, (2) symlinks that make those files "live" at
their expected `$HOME`/`~/.config` paths, (3) an idempotent Bash installer
that creates those symlinks and optionally installs the underlying
packages/tools, and (4) a small templating engine (`scripts/theme.sh`) that
generates theme-dependent config fragments from source-of-truth palette
files. Understanding the architecture means understanding these four
pieces and how they hand off to each other.

## Architecture Pattern: Symlink-Sourced Configuration

```
~/cumulus.dotfiles/config/sway   <──symlink──   ~/.config/sway
~/cumulus.dotfiles/zsh/.zshrc    <──symlink──   ~/.zshrc
~/cumulus.dotfiles/scripts/*.sh  <──symlink──   ~/.local/bin/cumulus-*
```

The repo directory is the **only real copy** of every managed file. Nothing
is copied into `$HOME`; `install.sh` creates symlinks pointing back into the
repo. Consequences of this choice (all deliberate):

- Editing `~/.config/sway/config` (e.g. from within Sway, or via an editor)
  edits the git-tracked file directly — no separate "sync my changes back"
  step exists or is needed.
- `install.sh` is safe to re-run at any time: if the target already is the
  correct symlink, it's a no-op; if the target is a *real* file/directory
  (e.g. first run on a fresh machine, or a config that predates this repo),
  it's moved to `~/.cumulus_backup/<timestamp>/` before linking — nothing
  is ever silently deleted.
- Multi-machine sync is just `git pull && ./install.sh` — no rsync, no
  stow-style dotfile manager, no extra dependency beyond git + bash.

## Installer Flow (`install.sh`)

`install.sh` runs, in order:

1. **`install_packages`** (default enabled; skip with `--no-packages` or `--links-only`) — detects `apt` vs
   `pacman` and installs the base package list (`sway wofi waybar kitty grim
   slurp wl-clipboard brightnessctl playerctl swaylock swayidle wdisplays jq
   libnotify-bin`). The Nerd Font is *not* in this list — see step 4.
2. **Symlink every entry in the `LINKS` associative array** (`src → dest`
   pairs, e.g. `config/sway → .config/sway`) via `link_one()`, which
   implements the backup-before-overwrite safety described above.
3. **`link_scripts()`** — globs `scripts/*.sh`, symlinks each into
   `~/.local/bin/cumulus-<name>` (stripping `.sh`), so every script in this
   repo automatically becomes a callable command with zero additional
   wiring when you add a new file there.
4. **`scripts/install-fonts.sh apply`** — installs the JetBrainsMono Nerd
   Font unconditionally, on every invocation (not gated behind `--zsh` or
   `--packages`). This is deliberate: `config/{kitty,waybar,wofi,sway}`
   hardcode `"JetBrainsMono Nerd Font"` as their font-family, so without it
   every icon/glyph in those configs silently renders as a box — a plain
   `./install.sh` with no flags needs a working font just as much as one
   with `--zsh`. Downloads the release zip from GitHub upstream (works
   identically on apt and pacman — no AUR/pacman package needed), skips the
   download if `fc-list` already reports it installed. `install-zsh.sh`
   calls this same script rather than duplicating the logic.
5. **Apply the saved theme** — `scripts/theme.sh apply` (or shows the
   `--dry-run` equivalent), so the Catppuccin flavor/background mode chosen
   previously (or the `mocha`/flat default on a fresh machine) is always in
   effect after installing.
6. **Run Neovim & Tool Installers** — Neovim deployment (`install-nvim-deps.sh` and `install-nvim.sh`) runs by default (skip with `--no-nvim` or `--links-only`). Additional tool installers (`--zsh` / `--apps` / `--devops` / `--browser`) call their corresponding `scripts/install-<name>.sh`; `--all-tools` auto-discovers and runs every `scripts/install-*.sh` present.
7. **`scripts/validate.sh`** — runs automatically at the end of every
   non-dry-run invocation (skip with `--no-validate`) to catch regressions
   immediately rather than at the next reboot/reload.

`--dry-run` threads through the entire flow: every `run()` call either
executes the command or just echoes it, and this flag is forwarded into
every installer script it calls, so `./install.sh --dry-run --all-tools`
previews the *entire* end-to-end setup with zero side effects.

## Theme Rendering Pipeline (`scripts/theme.sh`)

This is the one piece of the repo with genuine "build/generate" logic
rather than pure symlinking, because config file formats disagree about
how `include`/`import` resolves paths:

| App | Include mechanism | Path resolution | Approach used |
|---|---|---|---|
| sway | native `include colors.conf` | relative to the *including config file* | generated `colors.conf` include, safe |
| kitty | native `include colors.conf` | relative to the *including config file* | generated `colors.conf` include, safe |
| waybar | GTK CSS `@import url(...)` | relative to the **process's CWD** (not the CSS file's location) | **not used** — breaks when waybar/wofi are launched by sway with an unpredictable CWD |
| wofi | GTK CSS `@import url(...)` | same CWD-relative bug | **not used**, same reason |

Because of that CWD bug (discovered via live testing — `wofi --show drun`
worked when launched from the config's own directory but failed with
`Failed to import: ... No such file or directory` from any other CWD),
waybar and wofi don't use includes/imports at all. Instead:

```
themes/palettes/<flavor>.sh   (source-of-truth hex colors, git-tracked)
        │  sourced by
        ▼
scripts/theme.sh generate_configs()
        │
        ├─→ config/sway/colors.conf     (sway include — client colors + exec_always swaybg)
        ├─→ config/kitty/colors.conf    (kitty include — color directives)
        ├─→ config/waybar/style.css     (rendered in full from style.css.tmpl via sed)
        └─→ config/wofi/style.css       (rendered in full from style.css.tmpl via sed)
```

The four generated files above are **gitignored** — only the `.tmpl`
templates (`@@PLACEHOLDER@@` tokens) and the `themes/palettes/*.sh` source
files are tracked. This keeps "what a flavor looks like" and "what's
currently rendered" cleanly separated: regenerating for a new flavor never
shows up as a spurious diff against the template.

### State & subcommands

Theme choice persists at `~/.config/cumulus/theme/state` (`FLAVOR=`,
`MODE=`, `WALLPAPER=`, `WALLPAPER_SOURCE=`, `INTERVAL=`, and
`NVIM_COLORSCHEME=` — plain
`KEY=VALUE` lines, directly `source`-able):

- `theme.sh set <flavor> [--flat | --theme-default | --wallpaper <path> | --rotate [--interval N] | --preserve-background]` — validates the flavor against `themes/palettes/*.sh`, follows the selected flavor's tracked SVG when `--theme-default` is used, preserves `WALLPAPER_SOURCE=user` overrides during theme changes, regenerates all four config fragments, reloads sway (`swaymsg reload`), and updates the state file. `--preserve-background` is used by Neovim synchronization to retain the current wallpaper/rotation mode.
- `theme.sh apply` — re-applies whatever's in the state file; this is what `install.sh` calls on every run, and what you'd wire into a login hook.
- `theme.sh next` — advances rotation by one wallpaper; called by the systemd timer, but safe to run manually too.
- `theme.sh list` / `theme.sh current` — introspection, no side effects.

### Runtime refresh coordination

After state and generated files are persisted, `theme.sh` invokes
`scripts/runtime-refresh.sh` in deterministic order: Sway, Waybar, Kitty,
Wofi, Neovim, and the optional GNOME/GTK color-scheme adapter. Each adapter is
best-effort and reports `refreshed` or `deferred or unavailable`; a missing
runtime endpoint never rolls back the saved theme. Kitty uses the restricted
socket configured through `CUMULUS_KITTY_SOCKET`, and Neovim refresh only
connects to per-user Unix sockets before sending
`cumulus.theme.load_saved_theme()`.

`scripts/lock.sh` reads the canonical state and palette at invocation time, so
new lock-screen sessions always use the active theme even though an existing
locked session is not live-reloaded. The state writer uses a temporary file and
atomic rename, preventing an interrupted theme change from leaving partial
`KEY=VALUE` state.

### Wallpaper rotation via systemd `--user` timer

Rotation deliberately avoids a background `while true; do sleep; done` loop
process — instead, `write_rotate_units()` generates
`~/.config/systemd/user/cumulus-wallpaper-rotate.service` (oneshot, runs
`theme.sh next`) and `.timer` (`OnUnitActiveSec=<interval>`,
`Persistent=true`), then `systemctl --user daemon-reload && enable --now`.
This means: rotation survives reboots without needing an autostart entry
that re-launches a loop, there's no orphan process to accidentally leave
running, and switching back to `--flat`/`--wallpaper` mode cleanly disables
the timer (`disable_rotate_units()`) rather than needing to hunt down and
kill a background PID.

## Script Conventions

Every script under `scripts/` follows the same shape, established early and
kept consistent as new scripts were added:

```bash
set -euo pipefail
log()  { printf '\033[1;34m[<tag>]\033[0m %s\n' "$*"; }
run()  { if $DRY_RUN; then echo "+ $*"; else eval "$@"; fi }
# ... argument parsing for --dry-run / -h/--help ...
```

Installers (`install-*.sh`) additionally follow: idempotent (skip
already-installed things), support both apt and pacman where relevant, and
accept `--dry-run` to preview without side effects. `-h`/`--help` on every
script prints its own header comment (`grep '^#' "$0" | sed 's/^#//'`) — so
the header comment block *is* the user-facing help text; keep it accurate
and it never needs to be duplicated elsewhere.

### Symlink-safe self-location (important gotcha)

Because every script in `scripts/` is invoked through a symlink in
`~/.local/bin/cumulus-<name>`, any script that needs to find its own
repo location (to read `themes/`, other scripts, etc.) **must** resolve the
*real* path first:

```bash
SELF="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(cd "$(dirname "$SELF")/.." && pwd)"
```

Using `dirname "${BASH_SOURCE[0]}"` directly (without `readlink -f` first)
resolves to `~/.local/bin` — the symlink's directory — not the repo. This
bug was hit and fixed across `theme.sh`, `lock.sh`, `update.sh`,
`backup.sh`, and `validate.sh`; any new script that needs `$DOTFILES_DIR`
must use the `readlink -f` form from the start.

## Directory-Backed Accounts (AD/LDAP/SSSD) — `chsh` Gotcha

`install-zsh.sh`'s `set_default_shell()` doesn't call `chsh` unconditionally
and trust it to succeed. On a machine where the account is managed by
Active Directory/LDAP via SSSD (resolves through `getent passwd`/NSS, but
has no line in local `/etc/passwd`), `chsh` fails — observed as either
`chsh: user '<name>' does not exist in /etc/passwd` or
`chsh: PAM: Authentication failure`, depending on the session/PAM stack.
Since every script in this repo runs under `set -euo pipefail`, letting that
failure propagate would abort the rest of `install-zsh.sh` (font install,
default-editor setup, etc. would silently never run).

The fix: attempt `chsh` first (works for regular local accounts), and on
*any* failure, fall back to `sudo usermod -s <shell> <user>`, which goes
through NSS and correctly updates directory-backed accounts too. If both
fail, it prints a warning (not a fatal error) pointing at the two real
remaining options — an admin-side `loginShell` change, or a login-shell
override via `~/.bash_profile` — rather than crashing the installer.
Any future script that shells out to account-management commands
(`chsh`, `chfn`, `passwd`, etc.) should follow the same
try-then-fall-back-then-warn pattern instead of assuming a plain
`/etc/passwd`-backed account.

## Live-Resolved Config Parsing — `whichkey.sh`

`config/sway/scripts/whichkey.sh` renders the keybinding cheatsheet from
`swaymsg -t get_config` — the compositor's actual in-memory, fully resolved
config (all `include`d files and `set $var` substitutions already expanded)
— rather than `cat`-ing `~/.config/sway/config` directly. This matters
because `config/sway/config` does `include colors.conf`, and any keybinds
that ever end up in an included file (not the case today, but plausible)
would be silently missing from the cheatsheet if it only read the
top-level file. Falls back to reading the file directly (`$SWAY_CONFIG` or
`~/.config/sway/config`) only if `swaymsg`/`jq` aren't available, e.g. when
testing outside a running Sway session. Same rule applies to any future
tool that needs to reflect "what Sway currently thinks its config is":
prefer `swaymsg -t get_config` over reading files off disk.

## Cross-Distro Support

Two package managers are supported end-to-end: **apt** (Ubuntu/Debian) and
**pacman** (Arch), with AUR as a fallback for Arch-only packages that have
no equivalent in Arch's official repos (currently just Google Chrome — see
`scripts/install-browser.sh`). The Nerd Font is **not** an AUR-only concern
any more: `scripts/install-fonts.sh` downloads it straight from the
upstream `ryanoasis/nerd-fonts` GitHub release on both distros, so it needs
no distro-specific package at all. Every installer script that touches
packages branches on `command -v apt`/`command -v pacman` and implements
both paths; AUR installs additionally check for `yay`/`paru` and print
manual instructions if neither is present rather than trying to bootstrap
an AUR helper (intentionally out of scope — installing an AUR helper is a
security-sensitive, user-judgment step).

## Known Constraints / Non-Goals

- This is a **personal** cumulus.dotfiles repo, not a general-purpose dotfiles
  framework — hardcoded assumptions (single user, specific font/terminal
  choices) are intentional, not oversights.
- No automated test suite in the CI sense — validation is `scripts/validate.sh`
  (read-only checks against the live system) plus manual `bash -n` /
  `sway --validate` / `--dry-run` runs before every commit, documented in
  [development-guide.md](./development-guide.md).
- `themes/wallpapers/` ignores personal raster/non-redistributable assets by
  design, while the small original SVG theme defaults and attribution record
  are tracked.
