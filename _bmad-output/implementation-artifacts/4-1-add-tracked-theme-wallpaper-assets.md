---
story_key: 4-1-add-tracked-theme-wallpaper-assets
epic: 4
story: 4.1
title: Add Tracked Theme Wallpaper Assets
status: review
---

# Story 4.1: Add Tracked Theme Wallpaper Assets

## Story

As a user selecting a desktop theme,
I want each theme to have a tracked default wallpaper,
so that cloud and Catppuccin themes have a complete visual identity.

## Acceptance Criteria

1. Given each supported theme exists, when its default is requested, then a
   redistributable tracked SVG asset exists with a deterministic flavor mapping.
2. Given the default asset is distributed, then its source, authorship, and
   license/attribution are documented.
3. Given a personal raster or other wallpaper is added, when git status is
   checked, then the personal asset is ignored.
4. Given a tracked default is selected, when theme state is persisted, then the
   state identifies it as `WALLPAPER_SOURCE=theme-default`.
5. Given a theme-default wallpaper is unavailable, when it is requested, then
   the theme engine falls back to flat mode rather than emitting a broken
   wallpaper command.

## Tasks / Subtasks

- [x] Audit tracked default assets and attribution (AC: 1–3)
  - [x] Provide one SVG for mocha, macchiato, frappe, latte, aws, azure, gcp,
    and oci.
  - [x] Keep assets original or document redistribution rights precisely.
  - [x] Keep personal wallpaper extensions ignored while allowing tracked SVGs.
- [x] Integrate deterministic palette-to-wallpaper lookup (AC: 1, 4, 5)
  - [x] Extend `scripts/theme.sh` without editing generated configuration.
  - [x] Preserve existing flat, static, and rotation modes.
  - [x] Validate missing-default behavior.
- [x] Add asset and state tests (AC: 1–5)
  - [x] Test every supported flavor resolves its own asset.
  - [x] Test attribution and ignore behavior.
  - [x] Test missing default fallback.
- [x] Run syntax checks, theme validation, and `git diff --check`.

## Dev Notes

- Assets live under `themes/wallpapers/`.
- Generated files under `config/sway/`, `config/kitty/`, `config/waybar/`,
  and `config/wofi/` remain derived and must not be hand-edited.
- `scripts/theme.sh` is the canonical state and rendering engine.
- Existing state fields must remain compatible; new source metadata must be
  additive and migration-safe.
- Do not make user wallpapers tracked accidentally through broad negation
  patterns in `.gitignore`.
- Test both direct `--theme-default` selection and application of saved state.

### References

- [Source: docs/epics.md#Story 4.1: Add Tracked Theme Wallpaper Assets]
- [Source: docs/epics.md#FR14: Tracked theme defaults]
- [Source: docs/architecture.md#State & subcommands]
- [Source: scripts/theme.sh]
- [Source: .gitignore]
- [Source: themes/palettes/]
- [Source: project-context.md#Critical Implementation Rules]

## Dev Agent Record

### Agent Model Used

GPT-5.6 Luna

### Debug Log References

- Existing implementation added eight SVG defaults and an attribution record;
  validation must verify that the repository ignore rules do not hide them.

### Completion Notes List

- Verified all eight theme assets, attribution, tracked SVG exceptions, and
  ignored personal wallpaper behavior.
- Verified direct theme-default selection, custom wallpaper preservation, and
  missing-custom fallback to the new theme default.
- Validation passed: Bash syntax checks, wallpaper/state tests, and
  `git diff --check`.

### File List

- `_bmad-output/implementation-artifacts/4-1-add-tracked-theme-wallpaper-assets.md`
- `.gitignore`
- `scripts/theme.sh`
- `themes/wallpapers/ATTRIBUTION.md`
- `themes/wallpapers/mocha.svg`
- `themes/wallpapers/macchiato.svg`
- `themes/wallpapers/frappe.svg`
- `themes/wallpapers/latte.svg`
- `themes/wallpapers/aws.svg`
- `themes/wallpapers/azure.svg`
- `themes/wallpapers/gcp.svg`
- `themes/wallpapers/oci.svg`
- `tests/theme-wallpapers.sh`
