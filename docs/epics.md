---
stepsCompleted: ['requirements-extraction', 'epic-design', 'story-creation']
inputDocuments:
  - docs/architecture.md
  - project-context.md
  - /home/luhenr@ad.global/.config/nvim/_bmad-output/planning-artifacts/prd-cumulus-nvim.md
  - /home/luhenr@ad.global/.config/nvim/_bmad-output/planning-artifacts/architecture-cumulus.md
scope: 'Shared AWS/Azure/GCP/OCI theme integration between cumulus.dotfiles and Cumulus Neovim'
---

# cumulus.dotfiles - Epic Breakdown

## Overview

This document decomposes the requested cross-repository cloud-theme integration
into implementable epics and stories. Existing Catppuccin desktop themes remain
supported. The desktop theme state is the proposed canonical state, while
Neovim keeps a standalone fallback when the desktop repository is unavailable.

## Requirements Inventory

### Functional Requirements

FR1: Add AWS, Azure, GCP, and OCI palette definitions to
`cumulus.dotfiles/themes/palettes/` using the existing 26-variable desktop
palette contract.

FR2: Preserve the existing Catppuccin Mocha, Macchiato, Frappe, and Latte
themes without changing their current behavior.

FR3: Add palette metadata that maps each desktop theme to its Neovim
colorscheme name.

FR4: Extend `cumulus-theme` to list, validate, apply, and persist the cloud
themes using the existing Sway, kitty, waybar, and wofi rendering pipeline.

FR5: Make `~/.config/cumulus/theme/state` the shared theme state and preserve
the existing background mode, wallpaper, and rotation fields.

FR6: Update the Neovim theme module to read the shared state, translate shared
theme names such as `aws` to colorschemes such as `aws-theme`, and fall back to
Neovim-local state when the shared state is unavailable.

FR7: Allow changing the theme from Neovim to update the shared state and invoke
the desktop theme command without recursive theme updates.

FR8: Update the Sway/wofi picker and Neovim picker to use consistent labels and
show the currently active theme.

FR9: Keep the existing Neovim semantic highlight engines for syntax, floating
windows, diagnostics, Telescope, dashboard, statusline, and bufferline.

FR10: Provide a validation path for palette completeness, generated output,
shared-state validity, and Neovim colorscheme availability.

### NonFunctional Requirements

NFR1: Theme changes must be idempotent and safe to repeat.

NFR2: Desktop theme changes must remain compatible with the current symlink
deployment model and generated-file pipeline.

NFR3: Waybar and wofi must continue using full template rendering rather than
relative GTK CSS imports.

NFR4: New Bash behavior must follow the repository's `set -euo pipefail`,
`readlink -f`, `--dry-run`, and validation conventions.

NFR5: Theme switching must remain usable when Sway is not running; changes
should persist and apply on the next session.

NFR6: Neovim must remain usable independently of `cumulus.dotfiles`.

NFR7: Cloud palette foreground/background pairs must meet a documented readable
contrast threshold for editor text, selections, diagnostics, and picker entries.

NFR8: Existing Catppuccin users must not lose their current saved theme or
background configuration during migration.

### Additional Requirements

- `scripts/theme.sh` is the desktop theme source of truth and already persists
  `FLAVOR`, `MODE`, `WALLPAPER`, and `INTERVAL`.
- Generated files under `config/sway/`, `config/kitty/`, `config/waybar/`, and
  `config/wofi/` remain derived artifacts and must not become hand-maintained
  theme sources.
- Neovim theme modules live under `~/.config/nvim/lua/cumulus/theme/` and
  colorscheme entrypoints live under `~/.config/nvim/colors/`.
- The Neovim architecture requires a centralized theme engine and direct
  `lazy.nvim` plugin ownership; this work must not reintroduce LazyVim coupling.
- Existing cloud palettes provide semantic roles such as `bg`, `fg`,
  `primary`, `secondary`, `error`, `bg_float`, `bg_cursorline`, and
  `bg_selection`; those roles must map deterministically to the desktop palette
  contract.
- The four cloud themes are dark-first. Light variants are out of scope unless
  explicitly added later.

### UX Design Requirements

UX-DR1: Both pickers must identify the active theme before selection.

UX-DR2: Desktop and Neovim must present the same theme names and labels.

UX-DR3: A theme change initiated from either environment must converge on one
shared active theme rather than silently creating divergent desktop and Neovim
states.

UX-DR4: Canceling either picker must leave the current theme and generated
configuration unchanged.

UX-DR5: Existing Catppuccin choices and wallpaper modes must remain discoverable
after cloud themes are added.

FR11: `install.sh --nvim` must clone or update the canonical Cumulus Neovim
repository at `https://github.com/petrolal/cumulus.nvim.git`.

FR12: Neovim installation must safely back up existing real configuration files
and deploy the Cumulus Neovim symlink idempotently.

FR13: Neovim installation must run dependency and headless configuration
validation while preserving `--dry-run` and `--no-validate`.

FR14: Each supported theme must have a tracked, redistributable default
wallpaper asset and palette association.

FR15: Theme changes must preserve user-selected wallpapers while replacing
theme-default wallpapers with the new theme's default.

FR16: The desktop picker must distinguish theme-default wallpapers from user
wallpaper overrides.

FR17: Theme changes must coordinate runtime refreshes across Sway, Waybar,
kitty, Wofi, Neovim, and the next lock-screen invocation.

FR18: Runtime refresh failures must be reported as partial or deferred results
without losing the persisted theme state.

FR19: Theme changes must apply the selected semantic color scheme to supported
OS/GTK desktop settings and other configured system surfaces.

FR20: Flat background mode must use the active theme's base color consistently
across the Sway background and all generated desktop styles.

NFR9: Cumulus Neovim installation must use
`https://github.com/petrolal/cumulus.nvim.git` as its canonical source.

NFR10: Curated default wallpapers must be tracked with attribution/license
documentation; personal wallpaper files remain ignored.

NFR11: Runtime adapters must use restricted local IPC and must not enable
unbounded remote command execution.

NFR12: A missing runtime process must never make a valid theme change fail.

NFR13: OS-level color-scheme integration must detect unsupported environments
and report a deferred result without failing theme persistence.

NFR14: Flat-mode color propagation must use palette tokens rather than
hardcoded per-application colors.

NFR15: Shared theme state must be serialized safely; wallpaper paths and other
user-controlled values must not become executable shell input when read back.
State updates must use atomic replacement and preserve either a complete old
record or a complete new record.

NFR16: Validation and test commands must not mutate the host desktop session,
including its OS/GTK color-scheme preference, unless the test explicitly uses
an isolated adapter stub.

NFR17: Runtime IPC endpoints must be explicitly configured or discoverable,
restricted to the current user, and report unsupported or unavailable
endpoints without terminating a valid theme change.

UX-DR6: Installation must report desktop and Neovim setup as one coherent
workflow.

UX-DR7: Theme switching must distinguish complete, partial, and deferred
refresh outcomes.

UX-DR8: Switching themes must preserve an explicitly user-selected wallpaper.

UX-DR9: Theme notifications must identify whether OS-level color settings were
applied or deferred.

## FR Coverage Map

FR1: Epic 1 - Cloud palette definitions
FR2: Epic 1 - Catppuccin compatibility
FR3: Epic 1 - Cross-environment palette metadata
FR4: Epic 1 - Desktop theme command and rendering
FR5: Epic 1 - Canonical shared theme state
FR6: Epic 2 - Neovim shared-state adapter
FR7: Epic 2 - Bidirectional theme switching
FR8: Epic 2 - Consistent active-theme picker UX
FR9: Epic 2 - Preserve Neovim semantic highlight engines
FR10: Epic 2 - Cross-environment validation
FR11: Epic 3 - Cumulus Neovim installation
FR12: Epic 3 - Safe Neovim deployment
FR13: Epic 3 - Neovim validation integration
FR14: Epic 4 - Tracked theme defaults
FR15: Epic 4 - Custom wallpaper preservation
FR16: Epic 4 - Wallpaper picker behavior
FR17: Epic 5 - Runtime refresh coordination
FR18: Epic 5 - Partial refresh reporting
FR19: Epic 5 - OS/GTK color-scheme integration
FR20: Epic 5 - Flat background color propagation

### NFR Coverage

NFR1-NFR5: Epic 1 - Safe, idempotent, portable desktop theme behavior
NFR6-NFR8: Epic 2 - Neovim independence, contrast, and migration safety
NFR9: Epic 3 - Canonical Neovim source
NFR10: Epic 4 - Wallpaper distribution and licensing
NFR11-NFR12: Epic 5 - Restricted, failure-tolerant runtime refresh
NFR13-NFR17: Epics 1 and 5 - OS integration, safe state serialization,
testing isolation, and runtime endpoint handling

## Epic List

### Epic 1: Cloud Theme Selection for the Desktop

Users can choose and apply AWS, Azure, GCP, or OCI visual themes across Sway,
kitty, waybar, and wofi while retaining all existing Catppuccin choices,
wallpaper modes, and safe persistence behavior.

**FRs covered:** FR1, FR2, FR3, FR4, FR5

**Implementation notes:** Extend the existing shell palette contract and
`scripts/theme.sh`; keep generated files derived; preserve the current
`~/.config/cumulus/theme/state` format and migration behavior.

### Story 1.1: Add Cloud Palette Definitions

As a desktop user,
I want AWS, Azure, GCP, and OCI palettes registered beside Catppuccin,
so that every supported flavor uses the existing rendering contract.

**Acceptance Criteria:**

**Given** a cloud flavor is listed
**When** its palette is loaded
**Then** it defines all 26 required color variables, a stable label, and its
Neovim colorscheme metadata.

**Given** an invalid or incomplete palette is encountered
**When** validation runs
**Then** it fails with the flavor and missing variable identified.

### Story 1.2: Render Cloud Themes Across the Desktop

As a Sway user,
I want a selected cloud flavor rendered into Sway, kitty, Waybar, and Wofi,
so that all managed desktop surfaces share one palette.

**Acceptance Criteria:**

**Given** a valid cloud flavor is selected
**When** `theme.sh set <flavor>` runs
**Then** all four generated config fragments are rendered from palette tokens.

**Given** Sway is unavailable
**When** the flavor is selected
**Then** state and generated files still update for the next session.

**Given** flat mode is selected
**When** styles are generated
**Then** Sway and Waybar backgrounds use the exact same `BASE` token.

### Story 1.3: Persist Theme State Safely

As a user switching themes,
I want the shared state to survive repeated changes and interruptions,
so that a partial write cannot create an invalid desktop configuration.

**Acceptance Criteria:**

**Given** a theme change succeeds
**When** the state file is read
**Then** it contains the complete `FLAVOR`, `MODE`, `WALLPAPER`,
`WALLPAPER_SOURCE`, `INTERVAL`, and `NVIM_COLORSCHEME` record.

**Given** a wallpaper path contains spaces or shell metacharacters
**When** the state is persisted and reloaded
**Then** it remains data, never executable shell input.

**Given** persistence is interrupted
**When** the state file is inspected
**Then** it contains either the complete previous record or complete new record.

### Epic 2: Synchronized Cloud Theme Experience

Users can switch themes from either the desktop picker or Neovim and see the
same active theme reflected in both environments, with clear current-theme
markers, migration-safe preservation of existing Catppuccin state, and a
standalone Neovim fallback.

**FRs covered:** FR6, FR7, FR8, FR9, FR10

**Implementation notes:** Coordinate changes between this repository and
`~/.config/nvim`; retain Neovim's existing semantic highlight engines; preserve
existing `FLAVOR`, wallpaper, and rotation settings; validate shared state,
palette completeness, generated output, and readable contrast.

**Natural dependency:** Epic 2 consumes the shared palette metadata and state
contract delivered by Epic 1. Epic 1 remains fully usable without Neovim.

### Story 2.1: Read Shared Theme State in Neovim

As a Neovim user,
I want Neovim to read the canonical desktop theme state,
so that editor startup follows the active desktop flavor.

**Acceptance Criteria:**

**Given** a valid shared state exists
**When** Neovim starts
**Then** the shared flavor maps to the configured Neovim colorscheme.

**Given** shared state is missing, malformed, or unavailable
**When** Neovim starts
**Then** it uses its local fallback state without failing startup.

### Story 2.2: Synchronize Theme Changes Bidirectionally

As a user changing themes,
I want desktop and Neovim changes to converge on one state,
so that the two environments do not silently diverge.

**Acceptance Criteria:**

**Given** a theme is selected in Neovim
**When** the desktop command is available
**Then** the desktop state updates once without recursive updates.

**Given** the desktop command is unavailable
**When** a Neovim theme is selected
**Then** Neovim applies the theme locally and reports desktop synchronization
as deferred.

**Given** wallpaper or rotation state exists
**When** Neovim changes only the flavor
**Then** the existing background mode and path remain preserved.

### Story 2.3: Align Active-Theme Picker UX

As a user choosing a theme,
I want desktop and Neovim pickers to use matching labels and markers,
so that the current shared choice is obvious.

**Acceptance Criteria:**

**Given** a current flavor is persisted
**When** either picker opens
**Then** that flavor has a visible active marker and all supported flavors use
consistent names.

**Given** either picker is canceled
**When** it exits
**Then** no state, generated config, or colorscheme changes occur.

### Story 2.4: Preserve Neovim Semantic Highlight Engines

As a Neovim user,
I want theme changes to affect presentation without replacing semantic plugins,
so that diagnostics, Telescope, dashboard, statusline, and bufferline behavior
remain intact.

**Acceptance Criteria:**

**Given** a supported theme is applied
**When** Neovim loads the colorscheme
**Then** existing semantic highlight engines and plugin ownership remain
unchanged.

**Given** a cloud colorscheme is unavailable
**When** the theme is selected
**Then** Neovim reports the failure and applies its safe fallback.

### Story 2.5: Validate Cross-Environment Theme Availability

As a maintainer,
I want automated checks for shared state, palette metadata, and colorschemes,
so that synchronization failures are caught before use.

**Acceptance Criteria:**

**Given** all supported flavors are registered
**When** validation runs
**Then** every desktop palette metadata mapping and Neovim colorscheme entry is
checked.

**Given** a state record contains user-controlled wallpaper data
**When** validation parses it
**Then** values are treated as data and no shell commands execute.

### Epic 3: Cumulus Neovim Installation

Users can install or update the canonical Cumulus Neovim configuration from
the same workstation setup flow, with safe backups and validation.

**FRs covered:** FR11, FR12, FR13

### Story 3.1: Install or Update Cumulus Neovim

As a user installing the workstation,
I want `install.sh --nvim` to clone or update the canonical Cumulus Neovim
repository, so that the editor is available without manual setup.

**Acceptance Criteria:**

**Given** the canonical repository is absent
**When** `install.sh --nvim` runs
**Then** it clones `https://github.com/petrolal/cumulus.nvim.git`.

**Given** the repository already exists
**When** the installer runs
**Then** it verifies the expected origin, refuses uncommitted local changes,
uses `git pull --ff-only`, and reports network or repository errors clearly.

**Given** `--dry-run` is supplied
**When** the installer runs
**Then** it prints planned clone/update operations without changing files.

### Story 3.2: Deploy the Neovim Configuration Safely

As a user with an existing Neovim setup,
I want real configuration files backed up before Cumulus is linked,
so that installation never destroys my current setup.

**Acceptance Criteria:**

**Given** `~/.config/nvim` is a real file or directory
**When** deployment starts
**Then** it moves the existing path into the timestamped Cumulus backup area.

**Given** `~/.config/nvim` is already the correct symlink
**When** deployment starts
**Then** it performs no replacement.

### Story 3.3: Integrate Neovim Installation with Validation

As a user completing workstation setup,
I want desktop and Neovim validation to run together,
so that configuration failures are visible before I start working.

**Acceptance Criteria:**

**Given** `nvim` is available
**When** `install.sh --nvim` completes deployment
**Then** the Neovim headless validation suite runs.

**Given** an optional Neovim tool is unavailable
**When** validation runs
**Then** it reports a warning without hiding configuration failures.

### Epic 4: Theme-Aware Wallpaper Defaults

Users receive a complete theme identity while retaining control of personal
wallpapers.

**FRs covered:** FR14, FR15, FR16

### Story 4.1: Add Tracked Theme Wallpaper Assets

As a user selecting a desktop theme,
I want each theme to have a tracked default wallpaper,
so that cloud and Catppuccin themes have a complete visual identity.

**Acceptance Criteria:**

**Given** a supported theme exists
**When** its default is requested
**Then** a redistributable tracked SVG asset and attribution record exist, with
the source and license documented.

**Given** a personal wallpaper is added
**When** git status is checked
**Then** ignored personal assets are not included as repository changes.

### Story 4.2: Preserve User Wallpaper Overrides

As a user with a personal wallpaper,
I want theme changes to keep my chosen wallpaper,
so that switching colors does not overwrite my personalization.

**Acceptance Criteria:**

**Given** `WALLPAPER_SOURCE=user`
**When** the theme changes
**Then** the user wallpaper path remains unchanged.

**Given** `WALLPAPER_SOURCE=theme-default`
**When** the theme changes
**Then** the new theme's tracked default is selected.

**Given** the stored wallpaper is missing
**When** the theme changes
**Then** the new theme default is used, with flat color as the final fallback.

**Given** a wallpaper path contains spaces or shell metacharacters
**When** the state is persisted and reloaded
**Then** the path remains data and cannot execute shell input.

**Given** rotation mode is active
**When** the theme changes
**Then** the rotation mode, interval, and next-image behavior remain valid.

### Story 4.3: Expose Wallpaper Choice Clearly

As a user choosing a theme,
I want the picker to distinguish defaults from custom wallpapers,
so that I understand what will happen before applying a theme.

**Acceptance Criteria:**

**Given** the picker opens
**When** wallpaper choices are shown
**Then** theme default, custom static, rotation, and flat modes are distinguishable.

**Given** a user wallpaper is active
**When** a different theme is selected
**Then** the picker clearly reports that the custom wallpaper will be preserved.

**Given** the picker is canceled
**When** it exits
**Then** no state or generated configuration changes.

### Epic 5: Immediate Runtime Theme Refresh

Users see a theme change reflected in running supported applications without
logging out, while partial runtime failures remain visible and recoverable.

**FRs covered:** FR17, FR18, FR19, FR20

### Story 5.1: Define the Runtime Refresh Coordinator

As a user changing themes,
I want one command to coordinate all refresh actions,
so that every supported component receives the same update.

**Acceptance Criteria:**

**Given** a valid theme is selected
**When** state and generated files are updated
**Then** refresh adapters run in this order: Sway, Waybar, Kitty, Wofi,
Neovim, and OS/GTK.

**Given** an optional adapter is unavailable
**When** the refresh completes
**Then** the state remains persisted and the result identifies the partial
failure with refreshed and deferred adapter counts.

**Given** an adapter fails
**When** refresh continues
**Then** later independent adapters still run and the coordinator exits
successfully after reporting a partial result.

### Story 5.2: Refresh Desktop Runtime Components

As a desktop user,
I want running desktop components to reflect the new theme immediately,
so that I do not need to log out or manually restart applications.

**Acceptance Criteria:**

**Given** Sway, Waybar, kitty, or Wofi is running
**When** the theme changes
**Then** each supported component is refreshed through its documented mechanism.

**Given** Kitty's restricted remote-control socket is unavailable
**When** the theme changes
**Then** Kitty is reported as deferred while the persisted theme remains successful.

**Given** a Kitty socket is configured
**When** the theme changes
**Then** the socket is explicitly enabled, local-user-owned, and used only for
the color refresh command.

**Given** no runtime is available
**When** the theme changes
**Then** the theme is saved for the next launch without an installer failure.

**Given** the lock screen is invoked after a theme change
**When** `cumulus-lock` starts
**Then** it uses the active palette.

**Given** flat background mode is active
**When** the theme changes
**Then** Sway, Waybar, kitty, Wofi, and lock-screen styling use the active
theme's palette tokens without hardcoded color exceptions.

**Given** flat background mode is active
**When** the theme is rendered
**Then** the Waybar root background exactly matches the Sway flat background
`BASE` color.

### Story 5.3: Refresh Neovim Through Restricted RPC

As a Neovim user,
I want a desktop theme change to update my running Neovim session,
so that both environments stay synchronized.

**Acceptance Criteria:**

**Given** a running Neovim instance has a registered local socket
**When** the desktop theme changes
**Then** Neovim applies the matching colorscheme through its theme module.

**Given** multiple Neovim instances are running
**When** the desktop theme changes
**Then** the refresh coordinator discovers per-instance sockets, restricts them
to the current user, and reports any stale or unreachable socket individually.

**Given** no Neovim socket exists
**When** the desktop theme changes
**Then** the state remains valid and Neovim applies it on next launch.

**Given** multiple Neovim sockets exist
**When** the desktop theme changes
**Then** duplicate socket paths are removed, stale sockets are reported
individually, and only current-user-owned sockets are contacted.

**Given** an RPC endpoint is configured
**When** refresh occurs
**Then** access is restricted to the local user/socket.

### Story 5.4: Validate Immediate Refresh and Failure Reporting

As a maintainer,
I want automated checks for runtime refresh behavior,
so that partial failures never silently create inconsistent themes.

**Acceptance Criteria:**

**Given** each runtime adapter is available
**When** the validation suite runs
**Then** each adapter reports success.

**Given** a theme change is interrupted during state persistence
**When** validation inspects the state file
**Then** it finds either the complete old state or the complete new state, never
an incomplete set of `KEY=VALUE` entries.

**Given** Kitty, Waybar, or Neovim is unavailable
**When** the validation suite runs
**Then** it reports a clear deferred/partial result without failing state validation.

**Given** runtime validation exercises OS/GTK integration
**When** the tests run
**Then** they use isolated adapter stubs and do not mutate the host desktop
preference.

**Given** a custom wallpaper is active
**When** runtime refresh is tested
**Then** its path remains unchanged.

### Story 5.5: Synchronize OS Color Scheme and System Surfaces

As a desktop user,
I want supported OS and GTK color settings to follow the selected theme,
so that applications outside the explicitly managed configs remain visually
consistent.

**Acceptance Criteria:**

**Given** the current session exposes a supported OS/GTK color-scheme setting
**When** a theme is applied
**Then** the setting is updated to the theme's dark/light mode and the result is
reported.

**Given** the session does not expose a supported color-scheme mechanism
**When** a theme is applied
**Then** theme state and managed desktop configurations still succeed, and the
OS integration is reported as deferred rather than failed.

**Given** flat background mode is selected
**When** generated desktop styles are rendered
**Then** their backgrounds and foregrounds derive from the active palette
contract, including the Sway background color and a Waybar root background that
matches it exactly.

**Given** OS integration changes a user setting
**When** the theme is changed again or reset
**Then** the integration does not overwrite unrelated desktop preferences.
