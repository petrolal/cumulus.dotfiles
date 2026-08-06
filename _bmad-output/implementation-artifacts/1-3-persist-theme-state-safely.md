---
story_key: 1-3-persist-theme-state-safely
epic: 1
story: 1.3
title: Persist Theme State Safely
status: done
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

- [x] Audit all state writers and readers (AC: 1–5)
  - [x] Confirm every successful write publishes all six state fields.
  - [x] Replace any state-file shell sourcing with a data-only parser.
  - [x] Validate flavor, mode, interval, and required values before apply,
    rotation, or adapter use.
  - [x] Preserve legacy state compatibility with documented defaults.
- [x] Harden atomic persistence and failure behavior (AC: 1, 3, 5)
  - [x] Keep temporary-file creation in the state directory with restrictive
    permissions.
  - [x] Publish state through atomic replacement only after validation.
  - [x] Ensure failed rendering or adapter setup cannot publish an incomplete
    state record.
  - [x] Keep runtime and OS/GTK adapters best-effort after persistence.
- [x] Add isolated state safety tests (AC: 1–5)
  - [x] Assert the complete six-field record after theme changes.
  - [x] Use spaces, shell metacharacters, and ampersands in wallpaper paths and
    assert no command executes.
  - [x] Test legacy and malformed state handling.
  - [x] Exercise apply and rotation state reload paths.
  - [x] Test interrupted/failed publication using temporary repositories and
    command stubs without mutating the host desktop.
- [x] Run syntax checks, all theme/state tests, and `git diff --check`.

### Review Findings

- [x] [Review][Patch] Restrict persisted and requested flavor names before
  palette sourcing [scripts/theme.sh:77-80, 136, 376] — path traversal can
  select and execute an arbitrary local shell file.
- [x] [Review][Patch] Escape or reject wallpaper paths before embedding them
  in Sway commands [scripts/theme.sh:143-150] — quotes, command substitutions,
  or newlines can alter the generated shell command.
- [x] [Review][Patch] Publish rotation state only after successful rendering
  [scripts/theme.sh:444-447] — `next` can persist a new wallpaper while
  generated configuration still reflects the old one.
- [x] [Review][Patch] Roll back generated fragments if publication fails
  midway [scripts/theme.sh:212-216] — independent `mv` operations can leave
  Sway, kitty, Waybar, and Wofi on mixed generations.
- [x] [Review][Patch] Reject control characters in serialized state values
  [scripts/theme.sh:46-60] — line-delimited records cannot represent newline
  paths without corrupting the state file.
- [x] [Review][Patch] Validate or normalize `WALLPAPER_SOURCE`
  [scripts/theme.sh:383-390, 416-417] — unsupported values are republished
  as if they were valid state.
- [x] [Review][Patch] Diagnose malformed saved modes before safe fallback
  [scripts/theme.sh:117-121, 377] — invalid modes currently become flat
  silently.
- [x] [Review][Patch] Reject or define precedence for conflicting wallpaper
  options [scripts/theme.sh:264-267] — supplying both `--theme-default` and
  `--wallpaper` can select the wrong source.
- [x] [Review][Patch] Disable stale rotation timers after `apply` falls back
  from rotate to flat [scripts/theme.sh:402-418] — the old timer can continue
  invoking `next` against non-rotate state.
- [x] [Review][Patch] Add rotation reload and malformed-state coverage
  [tests/state-safety.sh:27-65] — `set --rotate`, `next`, invalid sources,
  invalid modes, and missing fields are not fully exercised.
- [x] [Review][Patch] Add failure-injection tests for interrupted publication
  [tests/state-safety.sh:18-65] — renderer or publication failures are not
  tested against preservation of the previous complete record.
- [x] [Review][Patch] Bound Neovim adapter RPC time [scripts/runtime-refresh.sh:62-64]
  — an unresponsive local socket can hang a valid theme change indefinitely.

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
- `cmd_apply` now normalizes legacy state and republishes a complete six-field
  record only after successful rendering.
- Saved flavor, mode, and interval values are validated before apply/rotation;
  runtime and OS/GTK adapters no longer execute state-file values.
- Added isolated coverage for complete records, legacy migration, shell
  metacharacters, ampersands, apply, rotation, and malformed state.
- Review fixes added safe palette/path handling, transactional generated-config
  publication with rollback, source/mode validation, rotation timer cleanup,
  and bounded Neovim refresh.
- Failure-injection tests verify generated fragments remain unchanged when
  publication fails midway.

### Completion Notes List

- Comprehensive implementation context created for state completeness,
  atomic replacement, safe parsing, adapter behavior, and interruption tests.

### File List

- `_bmad-output/implementation-artifacts/1-3-persist-theme-state-safely.md`
- `scripts/theme.sh`
- `scripts/runtime-refresh.sh`
- `scripts/os-colorscheme.sh`
- `tests/state-safety.sh`

## Change Log

- 2026-08-05: Implemented safe state migration and complete-record
  republishing, with full state-safety regression coverage. Story ready for
  review.
- 2026-08-05: Addressed all code-review findings and verified the complete
  regression suite. Story complete.
