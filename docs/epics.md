---
stepsCompleted: ['requirements-extraction', 'epic-design']
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

### NFR Coverage

NFR1-NFR5: Epic 1 - Safe, idempotent, portable desktop theme behavior
NFR6-NFR8: Epic 2 - Neovim independence, contrast, and migration safety

## Epic List

### Epic 1: Cloud Theme Selection for the Desktop

Users can choose and apply AWS, Azure, GCP, or OCI visual themes across Sway,
kitty, waybar, and wofi while retaining all existing Catppuccin choices,
wallpaper modes, and safe persistence behavior.

**FRs covered:** FR1, FR2, FR3, FR4, FR5

**Implementation notes:** Extend the existing shell palette contract and
`scripts/theme.sh`; keep generated files derived; preserve the current
`~/.config/cumulus/theme/state` format and migration behavior.

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
