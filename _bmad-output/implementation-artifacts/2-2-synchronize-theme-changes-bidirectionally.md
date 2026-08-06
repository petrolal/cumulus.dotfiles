---
story_key: 2-2-synchronize-theme-changes-bidirectionally
epic: 2
story: 2.2
title: Synchronize Theme Changes Bidirectionally
status: ready-for-dev
---

# Story 2.2: Synchronize Theme Changes Bidirectionally

## Story

As a user changing themes,
I want desktop and Neovim changes to converge on one state,
so that the two environments do not silently diverge.

## Acceptance Criteria

1. Given a theme is selected in Neovim, when the desktop command is available,
   then the desktop state updates once without recursive updates.
2. Given the desktop command is unavailable, when a Neovim theme is selected,
   then Neovim applies the theme locally and reports desktop synchronization as
   deferred.
3. Given wallpaper or rotation state exists, when Neovim changes only the
   flavor, then the existing background mode, path, source, and interval remain
   preserved.
4. Given the desktop command exits unsuccessfully, then the Neovim theme
   remains applied locally and the failure is reported without startup failure.
5. Given an invalid theme ID is requested, then no arbitrary colorscheme or
   desktop command is constructed; the safe configured fallback is used.

## Tasks / Subtasks

- [ ] Audit Neovim-to-desktop synchronization boundaries (AC: 1–5)
  - [ ] Preserve local colorscheme application before optional desktop sync.
  - [ ] Confirm the desktop invocation uses the canonical command and
    `--preserve-background`.
  - [ ] Ensure desktop refresh of Neovim only calls `load_saved_theme()` and
    cannot recursively invoke desktop synchronization.
- [ ] Harden synchronization failure and input handling (AC: 2, 4, 5)
  - [ ] Keep missing executable and nonzero command results as deferred/warn
    outcomes.
  - [ ] Validate theme IDs against the configured registry before applying.
  - [ ] Keep async callbacks safe when the editor is closing or unavailable.
  - [ ] Preserve wallpaper, rotation, source, and interval by delegating
    background handling to `cumulus-theme`.
- [ ] Add isolated synchronization tests (AC: 1–5)
  - [ ] Stub `cumulus-theme` and assert one invocation with the expected args.
  - [ ] Verify missing executable and nonzero exit notifications.
  - [ ] Verify local theme application succeeds when desktop sync is deferred.
  - [ ] Verify custom and rotation state fields are preserved by the desktop
    command contract.
  - [ ] Verify invalid theme IDs resolve only to configured fallback themes.
- [ ] Run headless Neovim validation, synchronization tests, and
  `git diff --check`.

## Dev Notes

- The implementation lives at
  `~/.config/nvim/lua/cumulus/theme/init.lua`.
- `M.set_theme(theme_id)` currently applies the configured colorscheme, then
  asynchronously invokes:
  `cumulus-theme set <theme> --preserve-background`.
- Desktop-to-Neovim refresh is handled by
  `cumulus.dotfiles/scripts/runtime-refresh.sh`, which sends only
  `cumulus.theme.load_saved_theme()` over a current-user socket. Do not make
  `load_saved_theme()` call `set_theme()`.
- `find_theme()` must remain registry-bound. Unknown IDs must not become
  arbitrary `colorscheme` command strings or shell arguments.
- Desktop persistence owns wallpaper and rotation fields. Neovim changes only
  the flavor and must not parse, rewrite, or replace those fields.
- Tests should use temporary state files and command stubs; never mutate the
  live desktop or user theme state.

### Project Structure Notes

- Update `~/.config/nvim/lua/cumulus/theme/init.lua`.
- Add tests under `~/.config/nvim/scripts/`.
- Keep desktop implementation changes out of generated configuration files.

### References

- [Source: docs/epics.md#Story 2.2: Synchronize Theme Changes Bidirectionally]
- [Source: docs/epics.md#FR7: Bidirectional theme switching]
- [Source: docs/architecture.md#Runtime refresh coordination]
- [Source: /home/luhenr@ad.global/.config/nvim/lua/cumulus/theme/init.lua]
- [Source: scripts/theme.sh]
- [Source: scripts/runtime-refresh.sh]
- [Source: project-context.md#Critical Implementation Rules]

## Dev Agent Record

### Agent Model Used

GPT-5.6 Luna

### Debug Log References

- Existing `set_theme()` already delegates background preservation to
  `cumulus-theme`; implementation requires isolated async success/failure
  coverage and strict registry validation.

### Completion Notes List

- Comprehensive context created for one-way command invocation, deferred
  synchronization, recursion prevention, and wallpaper-state preservation.

### File List

- `_bmad-output/implementation-artifacts/2-2-synchronize-theme-changes-bidirectionally.md`
