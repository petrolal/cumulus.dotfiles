---
story_key: 1-2-render-cloud-themes-across-the-desktop
epic: 1
story: 1.2
title: Render Cloud Themes Across the Desktop
status: review
---

# Story 1.2: Render Cloud Themes Across the Desktop

## Story

As a Sway user,
I want a selected cloud flavor rendered into Sway, kitty, Waybar, and Wofi,
so that all managed desktop surfaces share one palette.

## Acceptance Criteria

1. Given a valid cloud flavor is selected, when `theme.sh set <flavor>` runs,
   then Sway, kitty, Waybar, and Wofi generated fragments are rendered from
   that palette.
2. Given Sway is unavailable, when the flavor is selected, then state and
   generated files still update for the next session and the command reports
   runtime refresh as deferred rather than failing.
3. Given flat mode is selected, when styles are generated, then Sway and the
   Waybar root background use the exact same `BASE` token.
4. Given a cloud flavor is selected repeatedly, when rendering completes, then
   generated output is deterministic and no source templates or palette files
   are modified.
5. Given a palette or template value is invalid, when rendering runs, then it
   fails before publishing an invalid generated configuration.

## Tasks / Subtasks

- [x] Verify and harden cloud rendering (AC: 1–5)
  - [x] Render Sway colors and wallpaper command from palette tokens.
  - [x] Render kitty colors through the tracked include fragment.
  - [x] Render complete Waybar and Wofi CSS from templates.
  - [x] Ensure flat-mode Waybar root background equals `BASE`.
  - [x] Keep generated output deterministic and derived.
- [x] Define unavailable-runtime behavior (AC: 2)
  - [x] Persist and generate successfully outside Sway.
  - [x] Report deferred runtime adapters without masking rendering errors.
- [x] Add isolated rendering tests (AC: 1–5)
  - [x] Test each cloud flavor’s generated fragments.
  - [x] Assert required palette tokens appear in the correct outputs.
  - [x] Assert exact Waybar/Sway flat background equality.
  - [x] Test repeated rendering produces identical output.
  - [x] Test invalid palette/template input fails before publishing.
- [x] Run `bash -n scripts/theme.sh`, theme tests, runtime tests, and
  `git diff --check`.

## Dev Notes

- `scripts/theme.sh` is the only rendering and state entry point.
- Source files are `themes/palettes/*.sh` and
  `config/{waybar,wofi}/style.css.tmpl`.
- Generated files are:
  - `config/sway/colors.conf`
  - `config/kitty/colors.conf`
  - `config/waybar/style.css`
  - `config/wofi/style.css`
- Generated files are intentionally ignored and must not become hand-maintained
  sources.
- Waybar and Wofi require full template rendering; do not reintroduce relative
  GTK CSS imports.
- Runtime adapters are best-effort and must not turn a valid offline render
  into a failure.
- Tests must use temporary HOME and command stubs where live Sway or system
  services would otherwise be touched.

### References

- [Source: docs/epics.md#Story 1.2: Render Cloud Themes Across the Desktop]
- [Source: docs/epics.md#FR4: Desktop theme command and rendering]
- [Source: docs/epics.md#FR20: Flat background color propagation]
- [Source: docs/architecture.md#Theme Rendering Pipeline (`scripts/theme.sh`)]
- [Source: scripts/theme.sh]
- [Source: config/waybar/style.css.tmpl]
- [Source: config/wofi/style.css.tmpl]
- [Source: project-context.md#Critical Implementation Rules]

## Dev Agent Record

### Agent Model Used

GPT-5.6 Luna

### Debug Log References

- Existing cloud palettes and generated pipeline are present; this story
  requires deterministic rendering and isolated output assertions.

### Completion Notes List

- Added template contract validation and temporary-directory rendering before
  publishing generated fragments.
- Verified cloud rendering, exact flat `BASE` propagation, deterministic
  repeatability, offline Sway behavior, and invalid-template rejection.
- Validation passed: Bash syntax checks, rendering tests, runtime tests, and
  `git diff --check`.

### File List

- `_bmad-output/implementation-artifacts/1-2-render-cloud-themes-across-the-desktop.md`
- `scripts/theme.sh`
- `tests/theme-rendering.sh`
