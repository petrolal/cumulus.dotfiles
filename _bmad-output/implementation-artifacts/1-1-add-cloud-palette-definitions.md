---
story_key: 1-1-add-cloud-palette-definitions
epic: 1
story: 1.1
title: Add Cloud Palette Definitions
status: review
---

# Story 1.1: Add Cloud Palette Definitions

## Story

As a desktop user,
I want AWS, Azure, GCP, and OCI palettes registered beside Catppuccin,
so that every supported flavor uses the existing rendering contract.

## Acceptance Criteria

1. Given a cloud flavor is listed, when its palette is loaded, then it defines
   all 26 required desktop color variables, a stable user-facing label, and
   Neovim colorscheme metadata.
2. Given an invalid or incomplete palette is encountered, when validation runs,
   then it fails with the flavor and missing variable identified.
3. Given all existing Catppuccin palettes are loaded, when validation runs,
   then their variables and behavior remain unchanged.
4. Given a palette contains color values, when generated desktop configs use
   them, then values remain valid six-digit hex colors and do not introduce
   shell or template injection.
5. Given the flavor registry is listed, when `theme.sh list` runs, then all
   four cloud flavors and all four Catppuccin flavors appear exactly once.

## Tasks / Subtasks

- [x] Audit cloud palette files against the 26-variable contract (AC: 1–4)
  - [x] Verify AWS, Azure, GCP, and OCI define every required token.
  - [x] Verify `THEME_NAME`, `THEME_LABEL`, and `NVIM_COLORSCHEME` metadata.
  - [x] Validate all values against the repository’s hex color format.
  - [x] Confirm palette files contain data only and no executable behavior.
- [x] Preserve and validate Catppuccin compatibility (AC: 3, 5)
  - [x] Load mocha, macchiato, frappe, and latte through the same validator.
  - [x] Confirm `theme.sh list` has eight unique flavors and labels.
  - [x] Preserve existing palette file locations and generated-file conventions.
- [x] Add automated palette tests (AC: 1–5)
  - [x] Test required variables and metadata for every palette.
  - [x] Test missing-variable failure with an isolated temporary palette copy
    or validation harness.
  - [x] Test registry listing and duplicate-free flavor names.
- [x] Run `bash -n scripts/theme.sh`, palette tests, theme validation, and
  `git diff --check`.

## Dev Notes

- Palette sources live under `themes/palettes/*.sh`; generated files must not
  become palette sources.
- `scripts/theme.sh` is the canonical palette loader and currently validates
  26 variables in `validate_palette()`.
- Existing palette metadata is consumed by shared Neovim state; preserve
  `NVIM_COLORSCHEME` names exactly.
- Keep all palette values compatible with Sway, kitty, GTK CSS, and Wofi
  rendering.
- Tests must not alter the user’s live theme state or generated files; use
  temporary copies or restore isolated fixtures.
- Do not add a package dependency or a second palette registry.

### Required color variables

`BASE`, `MANTLE`, `CRUST`, `TEXT`, `SUBTEXT1`, `SUBTEXT0`, `SURFACE0`,
`SURFACE1`, `SURFACE2`, `OVERLAY0`, `BLUE`, `LAVENDER`, `SAPPHIRE`, `SKY`,
`TEAL`, `GREEN`, `YELLOW`, `PEACH`, `MAROON`, `RED`, `MAUVE`, `PINK`,
`FLAMINGO`, and `ROSEWATER`.

### References

- [Source: docs/epics.md#Story 1.1: Add Cloud Palette Definitions]
- [Source: docs/epics.md#FR1: Cloud palette definitions]
- [Source: docs/architecture.md#Theme Rendering Pipeline (`scripts/theme.sh`)]
- [Source: scripts/theme.sh]
- [Source: themes/palettes/]
- [Source: project-context.md#Critical Implementation Rules]

## Dev Agent Record

### Agent Model Used

GPT-5.6 Luna

### Debug Log References

- Cloud palette files already exist; this story formalizes their validation,
  registry behavior, and Catppuccin compatibility.

### Completion Notes List

- Added Catppuccin Neovim colorscheme metadata for all four Catppuccin flavors.
- Hardened `validate_palette()` to require metadata, matching flavor names,
  valid colorscheme identifiers, and six-digit hex values for all 26 tokens.
- Added isolated palette contract and registry tests, including incomplete
  palette rejection.
- Validation passed: Bash syntax checks, palette tests, and `git diff --check`.

### File List

- `_bmad-output/implementation-artifacts/1-1-add-cloud-palette-definitions.md`
- `scripts/theme.sh`
- `themes/palettes/aws.sh`
- `themes/palettes/azure.sh`
- `themes/palettes/gcp.sh`
- `themes/palettes/oci.sh`
- `themes/palettes/mocha.sh`
- `themes/palettes/macchiato.sh`
- `themes/palettes/frappe.sh`
- `themes/palettes/latte.sh`
- `tests/palettes.sh`
