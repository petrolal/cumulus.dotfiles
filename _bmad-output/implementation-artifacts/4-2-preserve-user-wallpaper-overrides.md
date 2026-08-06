---
story_key: 4-2-preserve-user-wallpaper-overrides
epic: 4
story: 4.2
title: Preserve User Wallpaper Overrides
status: done
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

- [x] Audit and harden wallpaper-source state handling (AC: 1–5)
  - [x] Preserve legacy states without `WALLPAPER_SOURCE` safely.
  - [x] Keep user paths unchanged when present.
  - [x] Replace theme defaults when flavor changes.
  - [x] Handle missing paths with default and flat fallbacks.
  - [x] Preserve rotation interval and valid image selection.
- [x] Verify picker cancellation and preservation behavior (AC: 1, 6)
  - [x] Ensure selection prompts do not mutate state before final choice.
  - [x] Ensure custom-wallpaper preservation messaging is accurate.
- [x] Add filesystem-based theme tests (AC: 1–6)
  - [x] Test custom wallpaper preservation.
  - [x] Test theme-default replacement.
  - [x] Test missing custom wallpaper fallback.
  - [x] Test missing default fallback to flat mode.
  - [x] Test rotation state and interval preservation.
  - [x] Test picker cancellation without configuration changes.
- [x] Run `bash -n scripts/theme.sh config/sway/scripts/theme-picker.sh`,
  theme tests, and `git diff --check`.

### Review Findings

- [x] [Review][Patch] Validate persisted flavor before `cmd_apply` and
  `cmd_next` source a palette [scripts/theme.sh:331, 407] — a crafted
  `FLAVOR` value can escape the palette directory and execute a local shell
  file.
- [x] [Review][Patch] Validate persisted mode before rendering
  [scripts/theme.sh:274-287, 349-367] — an invalid mode is treated as a
  wallpaper mode and can generate a broken `swaybg` command.
- [x] [Review][Patch] Repair or flatten missing rotate wallpapers during
  `apply` [scripts/theme.sh:351-367] — a rotate state with a missing image is
  rendered with an empty wallpaper path.
- [x] [Review][Patch] Preserve explicit custom SVG wallpapers as `user`
  [scripts/theme.sh:306-317] — any SVG below `themes/wallpapers/` is currently
  reclassified as `theme-default`, even when explicitly selected.
- [x] [Review][Patch] Replace unsafe rotation state rewriting
  [scripts/theme.sh:391-396] — `sed` replacement corrupts paths containing
  `&`, backslashes, or the delimiter.
- [x] [Review][Patch] Validate rotation intervals before writing state or
  systemd units [scripts/theme.sh:260-267, 328-341] — malformed values can
  leave persisted state updated while timer setup fails.
- [x] [Review][Patch] Extend rotation tests through `next` and `apply`
  [tests/theme-wallpapers.sh:68-78] — current coverage does not exercise
  rotation state rewriting or reapplication.

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
- Hardened state loading to parse `KEY=VALUE` records as data instead of
  executing user-controlled wallpaper values.
- Preserved rotation mode and interval, and added a flat-mode fallback when
  both the stored wallpaper and the new theme default are unavailable.
- Added isolated coverage for custom/default wallpaper transitions, rotation,
  fallback behavior, cancellation, and state-injection safety.

### File List

- `_bmad-output/implementation-artifacts/4-2-preserve-user-wallpaper-overrides.md`
- `scripts/theme.sh`
- `scripts/runtime-refresh.sh`
- `scripts/os-colorscheme.sh`
- `config/sway/scripts/theme-picker.sh`
- `tests/theme-wallpapers.sh`

## Change Log

- 2026-08-05: Implemented wallpaper preservation, safe state parsing, fallback
  behavior, and regression tests. Story ready for review.
- 2026-08-05: Addressed all code-review patches, including saved-state
  validation, rotation recovery, safe state rewriting, and expanded tests.
  Story complete.
