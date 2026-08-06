---
story_key: 1-3-persist-theme-state-safely
epic: 1
story: 1.3
title: Persist Theme State Safely
status: ready-for-dev
---

# Story 1.3: Persist Theme State Safely

## Story

As a user switching themes,
I want the shared state to survive repeated changes and interruptions,
so that a partial write cannot create an invalid desktop configuration.

## Acceptance Criteria

1. Given a theme change succeeds, when the state file is read, then it contains
   the complete `FLAVOR`, `MODE`, `WALLPAPER`, `WALLPAPER_SOURCE`, `INTERVAL`,
   and `NVIM_COLORSCHEME` record.
2. Given a wallpaper path contains spaces or shell metacharacters, when the
   state is persisted and reloaded, then it remains data and never executable
   shell input in the theme engine, runtime refresh, or OS color adapter.
3. Given persistence is interrupted, when the state file is inspected, then it
   contains either the complete previous record or the complete new record,
   never a partial set of fields.
4. Given a legacy state omits additive fields, when it is applied, then safe
   defaults are used without executing state values or breaking theme startup.
5. Given a malformed or invalid state record is encountered, when it is applied,
   then the command fails clearly or falls back safely before publishing broken
   generated configuration.

## Tasks / Subtasks

- [ ] Audit all state writers and readers (AC: 1–5)
  - [ ] Confirm every successful write publishes all six state fields.
  - [ ] Replace any state-file shell sourcing with a data-only parser.
  - [ ] Validate flavor, mode, interval, and required values before apply,
    rotation, or adapter use.
  - [ ] Preserve legacy state compatibility with documented defaults.
- [ ] Harden atomic persistence and failure behavior (AC: 1, 3, 5)
  - [ ] Keep temporary-file creation in the state directory with restrictive
    permissions.
  - [ ] Publish state through atomic replacement only after validation.
  - [ ] Ensure failed rendering or adapter setup cannot publish an incomplete
    state record.
  - [ ] Keep runtime and OS/GTK adapters best-effort after persistence.
- [ ] Add isolated state safety tests (AC: 1–5)
  - [ ] Assert the complete six-field record after theme changes.
  - [ ] Use spaces, shell metacharacters, and ampersands in wallpaper paths and
    assert no command executes.
  - [ ] Test legacy and malformed state handling.
  - [ ] Exercise apply and rotation state reload paths.
  - [ ] Test interrupted/failed publication using temporary repositories and
    command stubs without mutating the host desktop.
- [ ] Run syntax checks, all theme/state tests, and `git diff --check`.

## Dev Notes

- `scripts/theme.sh` is the canonical state writer and theme application entry
  point. The state file is
  `~/.config/cumulus/theme/state`, serialized as plain `KEY=VALUE` records.
- The required fields are `FLAVOR`, `MODE`, `WALLPAPER`, `WALLPAPER_SOURCE`,
  `INTERVAL`, and `NVIM_COLORSCHEME`.
- `write_state()` must write to a temporary file under the state directory,
  set mode `600`, then atomically replace the state path.
- State values are user-controlled data. Never use `source`, `eval`, or another
  executable parser for the state file. This rule applies to
  `scripts/theme.sh`, `scripts/runtime-refresh.sh`, and
  `scripts/os-colorscheme.sh`.
- Generated files remain derived from palette/template sources. A failed or
  invalid state operation must not publish broken generated configuration.
- Runtime refresh and OS/GTK integration are optional adapters. A missing or
  failing adapter must not roll back a valid persisted state.
- Preserve symlink-safe script location via
  `readlink -f "${BASH_SOURCE[0]}"` and use temporary HOME directories in tests.
- Existing Catppuccin and cloud theme behavior must remain unchanged.

### Project Structure Notes

- Primary implementation: `scripts/theme.sh`.
- State consumers: `scripts/runtime-refresh.sh` and
  `scripts/os-colorscheme.sh`.
- Tests belong under `tests/`; do not edit generated config fragments by hand.

### References

- [Source: docs/epics.md#Story 1.3: Persist Theme State Safely]
- [Source: docs/epics.md#NFR15: Safe shared theme state serialization]
- [Source: docs/architecture.md#State & subcommands]
- [Source: docs/architecture.md#Runtime refresh coordination]
- [Source: scripts/theme.sh]
- [Source: scripts/runtime-refresh.sh]
- [Source: scripts/os-colorscheme.sh]
- [Source: tests/theme-wallpapers.sh]
- [Source: project-context.md#Critical Implementation Rules]

## Dev Agent Record

### Agent Model Used

GPT-5.6 Luna

### Debug Log References

- Existing implementation uses atomic state replacement, but state consumers
  require a complete data-only reader and broader malformed-state coverage.

### Completion Notes List

- Comprehensive implementation context created for state completeness,
  atomic replacement, safe parsing, adapter behavior, and interruption tests.

### File List

- `_bmad-output/implementation-artifacts/1-3-persist-theme-state-safely.md`
