---
story_key: 5-1-define-the-runtime-refresh-coordinator
epic: 5
story: 5.1
title: Define the Runtime Refresh Coordinator
status: review
---

# Story 5.1: Define the Runtime Refresh Coordinator

## Story

As a user changing themes,
I want one command to coordinate all refresh actions,
so that every supported component receives the same update.

## Acceptance Criteria

1. Given a valid theme is selected, when state and generated files are updated,
   then refresh adapters run in a documented deterministic order.
2. Given an optional adapter is unavailable, when refresh completes, then the
   state remains persisted and the result identifies that adapter as deferred.
3. Given no supported runtime is available, when the theme changes, then the
   command succeeds after persisting state and reports deferred adapters.
4. Given an adapter fails, when later adapters run, then the failure does not
   prevent later independent adapters from executing.
5. Given a refresh is interrupted during state persistence, then the state file
   is either the complete previous state or complete new state.

## Tasks / Subtasks

- [x] Define and document coordinator contract (AC: 1–5)
  - [x] Establish and test adapter order: Sway, Waybar, Kitty, Wofi, Neovim,
    then OS/GTK.
  - [x] Define `refreshed`, `deferred`, and failure output.
  - [x] Keep the persisted theme authoritative.
- [x] Implement safe adapter orchestration (AC: 1–4)
  - [x] Reuse `scripts/theme.sh` as the only state/rendering source of truth.
  - [x] Execute each adapter independently and continue after failure.
  - [x] Avoid unbounded remote command execution.
  - [x] Return a stable coordinator result suitable for logs and tests.
- [x] Add coordinator tests (AC: 1–5)
  - [x] Stub adapters and assert deterministic order.
  - [x] Simulate unavailable and failing adapters.
  - [x] Assert later adapters still run.
  - [x] Verify atomic state-file behavior and complete key sets.
- [x] Run Bash syntax checks, theme integration tests, runtime tests, and
  `git diff --check`.

## Dev Notes

- The current coordinator is `scripts/runtime-refresh.sh`; extend it instead
  of creating duplicate refresh logic in `theme.sh`.
- `scripts/theme.sh` must persist state and generate files before invoking the
  coordinator.
- Runtime adapters are optional and must not make a valid theme selection fail.
- Kitty and Neovim IPC must remain local and ownership-restricted.
- Wofi is normally short-lived; its generated CSS applies on next launch
  unless a documented live process mechanism is available.
- The state writer must use temporary-file plus atomic rename semantics.
- Tests must run outside a live Sway session using command stubs.

### References

- [Source: docs/epics.md#Story 5.1: Define the Runtime Refresh Coordinator]
- [Source: docs/epics.md#FR17: Runtime refresh coordination]
- [Source: docs/epics.md#FR18: Partial refresh reporting]
- [Source: docs/architecture.md#Runtime refresh coordination]
- [Source: scripts/theme.sh]
- [Source: scripts/runtime-refresh.sh]
- [Source: scripts/os-colorscheme.sh]
- [Source: project-context.md#Critical Implementation Rules]

## Dev Agent Record

### Agent Model Used

GPT-5.6 Luna

### Debug Log References

- Existing coordinator logs per-adapter results but needs tests for ordering,
  continuation after failures, and machine-observable aggregate behavior.
- Existing theme state persistence was changed to atomic rename and must remain
  covered by this story.

### Completion Notes List

- Added explicit complete/partial aggregate refresh results while retaining
  best-effort adapter isolation.
- Verified deterministic Sway, Waybar, Kitty, Wofi, Neovim, and OS/GTK order.
- Verified Kitty failure does not prevent later adapters from running.
- Verified persisted state remains complete and unchanged during refresh.
- Validation passed: Bash syntax checks, coordinator integration tests, and
  `git diff --check`.

### File List

- `_bmad-output/implementation-artifacts/5-1-define-the-runtime-refresh-coordinator.md`
- `scripts/runtime-refresh.sh`
- `tests/runtime-refresh.sh`
