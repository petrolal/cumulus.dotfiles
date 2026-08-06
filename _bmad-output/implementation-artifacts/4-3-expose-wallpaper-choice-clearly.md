---
story_key: 4-3-expose-wallpaper-choice-clearly
epic: 4
story: 4.3
title: Expose Wallpaper Choice Clearly
status: done
---

# Story 4.3: Expose Wallpaper Choice Clearly

## Story

As a user choosing a theme,
I want the picker to distinguish defaults from custom wallpapers,
so that I understand what will happen before applying a theme.

## Acceptance Criteria

1. Given the picker opens, when wallpaper choices are shown, then theme
   default, custom static, rotation, and flat modes are visibly distinct.
2. Given a user wallpaper is active, when a different theme is selected, then
   the picker clearly reports that the custom wallpaper will be preserved unless
   the user explicitly chooses another wallpaper mode.
3. Given a theme-default wallpaper is active, when the picker opens, then the
   current flavor and current wallpaper source are identifiable before the user
   confirms a change.
4. Given the user cancels at the flavor, mode, interval, or custom-wallpaper
   selection prompt, then no state, generated configuration, or runtime refresh
   is changed.
5. Given no custom wallpaper exists for a custom or rotation selection, then
   the picker reports the actionable problem and exits without mutating theme
   state.
6. Given the picker selects a mode, then it remains a UI layer over
   `scripts/theme.sh`; wallpaper fallback, validation, persistence, and
   rendering logic are not duplicated in the picker.

## Tasks / Subtasks

- [x] Audit the current picker flow and state-source labeling (AC: 1–3, 6)
  - [x] Read the current state without executing wallpaper paths as shell code.
  - [x] Mark the active flavor and source/mode using labels users can
    distinguish at a glance.
  - [x] Keep the four choices explicit: flat color, theme default wallpaper,
    custom static wallpaper, and rotating wallpapers.
  - [x] Preserve the existing `theme.sh` command contract and do not duplicate
    its fallback logic.
- [x] Implement clear picker messaging and selection behavior (AC: 1–6)
  - [x] Explain custom-wallpaper preservation before a flavor change when
    `WALLPAPER_SOURCE=user`.
  - [x] Make the selected flavor/source context visible through prompts or
    notifications without exposing raw internal state unnecessarily.
  - [x] Ensure every canceled `wofi` prompt exits before invoking `theme.sh`.
  - [x] Keep missing-image handling actionable and side-effect free.
- [x] Add isolated picker tests (AC: 1–6)
  - [x] Stub `wofi`, `notify-send`, and `theme.sh` or use temporary HOME/state
    fixtures so tests do not require a running Sway session.
  - [x] Verify each mode is presented with distinct labels.
  - [x] Verify active custom wallpaper produces preservation messaging.
  - [x] Verify cancellation at each prompt does not invoke `theme.sh` and does
    not change a before/after state or generated-file snapshot.
  - [x] Verify empty custom/rotation choices report the problem without state
    mutation.
- [x] Run `bash -n config/sway/scripts/theme-picker.sh`, the picker/theme test
  suite, and `git diff --check`.

### Review Findings

- [x] [Review][Patch] Report missing rotation images before prompting for an
  interval [config/sway/scripts/theme-picker.sh:118-123] — the picker invokes
  `theme.sh` and gives no actionable picker-level error when rotation has no
  images.
- [x] [Review][Patch] Derive the active mode label from valid mode/source
  combinations [config/sway/scripts/theme-picker.sh:85-90] — stale source data
  can make a flat mode appear to be a custom wallpaper.
- [x] [Review][Patch] Cover interval and custom-wallpaper cancellation plus
  empty-image paths [tests/theme-picker.sh:76-97] — current tests cover flavor
  cancellation, mode cancellation, and flat selection only.
- [x] [Review][Patch] Verify cancellation leaves generated output unchanged
  [tests/theme-picker.sh:76-97] — current fixtures snapshot only state and
  replace the real theme engine with a logger.

## Dev Notes

- `config/sway/scripts/theme-picker.sh` is the only UI layer for this story.
  It currently presents flavor selection followed by background mode selection
  and delegates application to `scripts/theme.sh`.
- `scripts/theme.sh` is the canonical implementation for wallpaper-source
  semantics, fallback behavior, state persistence, generated configuration,
  and runtime refresh. Do not move or reimplement those rules in the picker.
- The shared state file is
  `~/.config/cumulus/theme/state` with `FLAVOR`, `MODE`, `WALLPAPER`,
  `WALLPAPER_SOURCE`, `INTERVAL`, and `NVIM_COLORSCHEME` entries. Legacy state
  may omit `WALLPAPER_SOURCE`; treat that as legacy/unknown for display.
- A user-selected wallpaper is identified by `WALLPAPER_SOURCE=user`;
  `theme-default`, `rotate`, and `flat` are distinct sources/modes. A theme
  change must not silently replace a user wallpaper.
- Canceled selection must return before invoking `theme.sh`; do not write
  state, generated files, timer units, or notifications that claim a change
  was applied.
- Personal raster/non-redistributable wallpapers under
  `themes/wallpapers/` remain ignored. Tracked SVG defaults are the only
  repository wallpaper assets intended for distribution.
- Scripts use `set -euo pipefail` and resolve their real location with
  `readlink -f "${BASH_SOURCE[0]}"`. Preserve this pattern.

### Current Implementation Context

- The picker currently labels flavor choices with `THEME_LABEL` and marks the
  current flavor with `✓`.
- It currently shows four mode labels, but the active mode/source is not shown
  in the mode prompt and the custom-preservation notification occurs after
  flavor selection.
- The picker currently selects custom and rotation files from
  `themes/wallpapers/` using raster extensions only; tracked SVG theme defaults
  are selected through `theme.sh --theme-default`.
- `theme.sh` performs all writes only after validation and configuration
  generation. Tests should isolate `HOME` and stub runtime-dependent commands
  where necessary.

### Project Structure Notes

- Update `config/sway/scripts/theme-picker.sh` for UI behavior.
- Add or extend a shell test under `tests/` for picker behavior; do not edit
  generated files under `config/sway/`, `config/kitty/`, `config/waybar/`, or
  `config/wofi/`.
- Use temporary HOME directories and command stubs for tests. Tests must not
  mutate the host desktop session.

### References

- [Source: docs/epics.md#Story 4.3: Expose Wallpaper Choice Clearly]
- [Source: docs/epics.md#FR16: Wallpaper picker behavior]
- [Source: docs/epics.md#UX-DR4: Canceling either picker]
- [Source: docs/epics.md#UX-DR8: Switching themes preserves an explicitly user-selected wallpaper]
- [Source: docs/architecture.md#State & subcommands]
- [Source: docs/architecture.md#Theme Rendering Pipeline]
- [Source: scripts/theme.sh]
- [Source: config/sway/scripts/theme-picker.sh]
- [Source: tests/theme-wallpapers.sh]
- [Source: project-context.md#Critical Implementation Rules]

## Dev Agent Record

### Agent Model Used

GPT-5.6 Luna

### Debug Log References

- Existing picker flow and theme-state contract were inspected before story
  creation. The implementation should focus on presentation and cancellation
  boundaries, not a second wallpaper engine.

### Completion Notes List

- Comprehensive implementation context created for active-source labeling,
  custom-wallpaper preservation messaging, cancellation safety, and isolated
  picker tests.
- Added active flavor and wallpaper-source context to picker prompts while
  keeping flat, theme-default, custom, and rotation choices explicit.
- Changed picker state loading to parse known fields as data rather than source
  arbitrary wallpaper paths.
- Added isolated picker tests covering cancellation, preservation messaging,
  active-source prompts, mode labels, and delegated theme application.

### File List

- `_bmad-output/implementation-artifacts/4-3-expose-wallpaper-choice-clearly.md`
- `config/sway/scripts/theme-picker.sh`
- `tests/theme-picker.sh`

## Change Log

- 2026-08-05: Implemented clear wallpaper-source UX and isolated picker
  regression tests. Story ready for review.
- 2026-08-05: Addressed all code-review patches, including empty-rotation
  handling, mode/source labeling, and complete cancellation coverage. Story
  complete.
