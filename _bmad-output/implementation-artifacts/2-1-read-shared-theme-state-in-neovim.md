---
story_key: 2-1-read-shared-theme-state-in-neovim
epic: 2
story: 2.1
title: Read Shared Theme State in Neovim
status: done
---

# Story 2.1: Read Shared Theme State in Neovim

## Story

As a Neovim user,
I want Neovim to read the canonical desktop theme state,
so that editor startup follows the active desktop flavor.

## Acceptance Criteria

1. Given a valid shared state exists, when Neovim starts, then the shared
   flavor maps to the configured Neovim colorscheme.
2. Given shared state is missing, malformed, or unavailable, when Neovim
   starts, then it uses its local fallback state without failing startup.
3. Given a shared state contains wallpaper paths or other user-controlled
   values, when Neovim reads it, then it parses values as data and does not
   execute shell input.
4. Given a shared flavor has no available Neovim colorscheme, when startup
   applies the theme, then Neovim reports the failure and uses the safe local
   fallback.

## Tasks / Subtasks

- [x] Audit the existing Neovim theme state engine (AC: 1–4)
  - [x] Identify the shared-state and local-fallback paths.
  - [x] Preserve the existing theme table, labels, and colorscheme mappings.
  - [x] Keep startup independent of `cumulus.dotfiles` availability.
- [x] Implement robust shared-state selection (AC: 1–4)
  - [x] Parse only the required `KEY=VALUE` data fields without shell
    evaluation.
  - [x] Validate the shared `FLAVOR` against the configured theme IDs.
  - [x] Prefer valid shared state, then local `COLORSCHEME`, then the safe
    default.
- [x] Add isolated Neovim tests (AC: 1–4)
  - [x] Test valid shared cloud and Catppuccin flavors.
  - [x] Test missing, malformed, and invalid shared state.
  - [x] Test local fallback when shared state is unavailable.
  - [x] Test a malicious wallpaper value remains data.
  - [x] Test unavailable colorscheme fallback without startup failure.
- [x] Run the Neovim headless validation available in the configuration
  repository and `git diff --check`.

### Review Findings

- [x] [Review][Patch] Treat `FLAVOR` as the required shared selection field and
  validate optional desktop fields only when present
  [lua/cumulus/theme/init.lua:41-70] — valid partial shared state currently
  falls back to stale local state.
- [x] [Review][Patch] Reject unknown shared-state keys
  [lua/cumulus/theme/init.lua:23-39] — arbitrary uppercase keys are accepted
  instead of marking the record malformed.
- [x] [Review][Patch] Make shared-state reads race-safe
  [lua/cumulus/theme/init.lua:25-27] — a file disappearing after
  `filereadable()` can abort startup.
- [x] [Review][Patch] Reject empty wallpaper values for non-flat modes
  [lua/cumulus/theme/init.lua:52-65] — malformed wallpaper/rotation records
  can be treated as valid.
- [x] [Review][Patch] Protect local fallback persistence errors
  [lua/cumulus/theme/init.lua:80-94] — an unwritable local state directory can
  turn a successful colorscheme load into a startup failure.
- [x] [Review][Patch] Resolve theme IDs to colorscheme names in health checks
  [lua/cumulus/health.lua:55-57] — health currently constructs `colorscheme
  azure` instead of `azure-theme`.
- [x] [Review][Patch] Test actual shared flavor-to-colorscheme application
  [scripts/test-theme-state.sh:58-60] — current coverage checks only the
  returned theme ID.
- [x] [Review][Patch] Cover missing, malformed, Catppuccin, and unavailable
  colorscheme states [scripts/test-theme-state.sh:62-78] — required fallback
  and failure paths are not fully exercised.

## Dev Notes

- Canonical Neovim implementation is outside this repository at
  `~/.config/nvim/lua/cumulus/theme/init.lua`; the story artifact remains
  tracked here because sprint planning is maintained by `cumulus.dotfiles`.
- Shared state is `~/.config/cumulus/theme/state`, written by
  `scripts/theme.sh`. Only `FLAVOR` is needed for theme selection; wallpaper,
  mode, and interval values must remain inert data.
- Local fallback state is stored at
  `vim.fn.stdpath("state") .. "/cumulus_theme"` with `COLORSCHEME=...`.
- Theme IDs and colorscheme names are defined by the `themes` table in the
  Neovim theme module. Unknown shared flavors must not silently construct
  arbitrary `colorscheme` commands.
- `vim.cmd` calls must remain protected by `pcall`; startup must fall back to
  AWS when the selected colorscheme is unavailable.
- Preserve the existing direct `lazy.nvim` plugin ownership and semantic
  highlight configuration.

### Project Structure Notes

- Update `~/.config/nvim/lua/cumulus/theme/init.lua` and add tests in the
  Neovim configuration's test/validation path if available.
- Do not edit generated desktop theme fragments for this story.

### References

- [Source: docs/epics.md#Story 2.1: Read Shared Theme State in Neovim]
- [Source: docs/epics.md#FR6: Neovim shared-state adapter]
- [Source: docs/architecture.md#State & subcommands]
- [Source: /home/luhenr@ad.global/.config/nvim/lua/cumulus/theme/init.lua]
- [Source: /home/luhenr@ad.global/.config/nvim/lua/cumulus/theme/aws.lua]
- [Source: project-context.md#Critical Implementation Rules]

## Dev Agent Record

### Agent Model Used

GPT-5.6 Luna

### Debug Log References

- Existing Neovim theme module already has shared-state lookup and local
  fallback behavior; implementation must harden malformed-state and command
  safety without changing theme mappings.
- Shared-state parsing now rejects malformed lines and duplicate keys, requires
  the complete desktop state record, and accepts an empty wallpaper only for
  flat mode.
- Added headless isolated tests for shared cloud selection, local fallback,
  malicious wallpaper data, and unavailable colorscheme fallback.
- Neovim validation passed: Lazy check, core options, all themes, healthcheck,
  and required modules.
- Review fixes added allowlisted/race-safe state parsing, optional desktop
  field compatibility, non-flat wallpaper validation, protected local-state
  writes, and correct healthcheck colorscheme resolution.
- Expanded tests cover missing state, Catppuccin mapping, actual colorscheme
  application, malformed records, and unavailable colorscheme fallback.

### Completion Notes List

- Comprehensive context created for shared-state parsing, fallback ordering,
  colorscheme safety, and isolated Neovim validation.

### File List

- `_bmad-output/implementation-artifacts/2-1-read-shared-theme-state-in-neovim.md`
- `/home/luhenr@ad.global/.config/nvim/lua/cumulus/theme/init.lua`
- `/home/luhenr@ad.global/.config/nvim/scripts/test-theme-state.sh`

## Change Log

- 2026-08-05: Hardened shared-state validation and fallback ordering; added
  isolated headless tests. Story ready for review.
- 2026-08-05: Addressed all code-review findings and reran the full Neovim
  validation suite. Story complete.
