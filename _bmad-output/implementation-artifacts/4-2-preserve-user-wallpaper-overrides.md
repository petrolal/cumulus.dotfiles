---
story_key: 4-2-preserve-user-wallpaper-overrides
epic: 4
story: 4.2
title: Preserve User Wallpaper Overrides
status: ready-for-dev
---

# Story 4.2: Preserve User Wallpaper Overrides

## Story

As a user with a personal wallpaper,
I want theme changes to keep my chosen wallpaper,
so that switching colors does not overwrite my personalization.

## Acceptance Criteria

1. Given `WALLPAPER_SOURCE=user`, when the theme changes with
   `--preserve-background`, then the user wallpaper path remains unchanged and
   the mode remains static wallpaper.
2. Given `WALLPAPER_SOURCE=theme-default`, when the theme changes with
   `--preserve-background`, then the new flavor's tracked default wallpaper is
   selected.
3. Given the stored user wallpaper is missing, when the theme changes with
   `--preserve-background`, then the new flavor default is selected if
   available.
4. Given the stored wallpaper and its flavor default are both unavailable,
   when the theme changes, then the engine falls back to flat mode with no
   broken wallpaper command.
5. Given rotation mode is active, when the theme changes with
   `--preserve-background`, then rotation mode, interval, and valid rotation
   behavior remain intact.
6. Given a theme change is canceled before application, when the picker exits,
   then state, wallpaper path, and generated configuration remain unchanged.

## Tasks / Subtasks

- [ ] Audit and harden wallpaper-source state handling (AC: 1–5)
  - [ ] Preserve legacy states without `WALLPAPER_SOURCE` safely.
  - [ ] Keep user paths unchanged when present.
  - [ ] Replace theme defaults when flavor changes.
  - [ ] Handle missing paths with default and flat fallbacks.
  - [ ] Preserve rotation interval and valid image selection.
- [ ] Verify picker cancellation and preservation behavior (AC: 1, 6)
  - [ ] Ensure selection prompts do not mutate state before final choice.
  - [ ] Ensure custom-wallpaper preservation messaging is accurate.
- [ ] Add filesystem-based theme tests (AC: 1–6)
  - [ ] Test custom wallpaper preservation.
  - [ ] Test theme-default replacement.
  - [ ] Test missing custom wallpaper fallback.
  - [ ] Test missing default fallback to flat mode.
  - [ ] Test rotation state and interval preservation.
  - [ ] Test picker cancellation without configuration changes.
- [ ] Run `bash -n scripts/theme.sh config/sway/scripts/theme-picker.sh`,
  theme tests, and `git diff --check`.

## Dev Notes

- `scripts/theme.sh` is the canonical state and rendering implementation.
- State is stored at `~/.config/cumulus/theme/state` with plain
  `KEY=VALUE` entries including `FLAVOR`, `MODE`, `WALLPAPER`,
  `WALLPAPER_SOURCE`, `INTERVAL`, and `NVIM_COLORSCHEME`.
- `--preserve-background` is used by Neovim synchronization and must remain
  idempotent.
- Generated files under `config/sway/`, `config/kitty/`, `config/waybar/`,
  and `config/wofi/` must remain derived.
- The picker is a UI layer over `theme.sh`; do not duplicate state or fallback
  logic there.
- Personal wallpapers remain ignored by `.gitignore`; tracked SVG defaults are
  the only wallpaper assets intentionally committed.
- Tests should use temporary HOME directories and compare state/configuration
  snapshots before and after cancellation or failed selection.

### References

- [Source: docs/epics.md#Story 4.2: Preserve User Wallpaper Overrides]
- [Source: docs/epics.md#FR15: Custom wallpaper preservation]
- [Source: docs/architecture.md#State & subcommands]
- [Source: scripts/theme.sh]
- [Source: config/sway/scripts/theme-picker.sh]
- [Source: tests/theme-wallpapers.sh]
- [Source: project-context.md#Critical Implementation Rules]

## Dev Agent Record

### Agent Model Used

GPT-5.6 Luna

### Debug Log References

- Existing theme-default and custom-wallpaper paths were manually exercised;
  this story requires dedicated coverage for rotation and cancellation.

### Completion Notes List

- Dedicated implementation context created for wallpaper-source preservation,
  fallback behavior, and picker cancellation.

### File List

- `_bmad-output/implementation-artifacts/4-2-preserve-user-wallpaper-overrides.md`
