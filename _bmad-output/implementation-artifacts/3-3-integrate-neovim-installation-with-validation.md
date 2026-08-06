---
story_key: 3-3-integrate-neovim-installation-with-validation
epic: 3
story: 3.3
title: Integrate Neovim Installation with Validation
status: review
---

# Story 3.3: Integrate Neovim Installation with Validation

## Story

As a user completing workstation setup,
I want desktop and Neovim validation to run together,
so that configuration failures are visible before I start working.

## Acceptance Criteria

1. Given `nvim` is available, when `install.sh --nvim` completes deployment,
   then headless Neovim validation runs.
2. Given an optional Neovim tool is unavailable, when validation runs, then a
   warning is reported without hiding repository or configuration failures.
3. Given `--no-validate` is supplied to `install.sh`, when `--nvim` runs, then
   Neovim headless validation is skipped while installation still completes.
4. Given `--dry-run` is supplied, when `install.sh --nvim` runs, then no
   validation command executes and all planned commands are printed.
5. Given headless validation fails, when installation runs, then it returns
   nonzero and identifies validation as the failing operation.

## Tasks / Subtasks

- [x] Verify and harden validation flag propagation (AC: 1–4)
  - [x] Keep dependency installation before configuration deployment.
  - [x] Forward `--dry-run` and `--no-validate` from `install.sh`.
  - [x] Preserve `--all-tools` discovery.
  - [x] Ensure skip paths return success rather than masking errors.
- [x] Define and test validation outcomes (AC: 1–5)
  - [x] Stub successful, missing, and failing `nvim` commands.
  - [x] Assert missing optional tools produce warnings.
  - [x] Assert validation failures remain fatal.
  - [x] Assert dry-run and no-validate do not invoke Neovim.
- [x] Run Bash syntax, installer integration, lifecycle tests, and
  `git diff --check` (AC: 1–5).

## Dev Notes

- `install.sh` calls `install-nvim-deps.sh` followed by
  `install-nvim.sh` for `--nvim`.
- `scripts/install-nvim.sh` owns headless validation; do not duplicate it in
  `install.sh`.
- Normal validation uses the available Neovim configuration validation command
  and must not silently convert configuration failures into warnings.
- Optional command absence is warning-only; clone, backup, symlink, and
  validation failures are distinct and must remain observable.
- Tests should use temporary HOME and PATH stubs rather than requiring a live
  Neovim session.

### References

- [Source: docs/epics.md#Story 3.3: Integrate Neovim Installation with Validation]
- [Source: docs/architecture.md#Installer Flow (`install.sh`)]
- [Source: install.sh]
- [Source: scripts/install-nvim.sh]
- [Source: scripts/install-nvim-deps.sh]
- [Source: project-context.md#Critical Implementation Rules]

## Dev Agent Record

### Agent Model Used

GPT-5.6 Luna

### Debug Log References

- Story 3.1 added lifecycle coverage for dry-run and `--no-validate`; reuse
  that temporary-environment pattern.

### Completion Notes List

- Added validation outcome coverage for successful, missing, and failing
  Neovim commands.
- Verified `--dry-run` and `--no-validate` skip Neovim invocation while
  preserving installation success.
- Verified validation failures remain fatal and missing Neovim produces a
  warning.
- Validation passed: Bash syntax checks, lifecycle tests, installer dry-run,
  and `git diff --check`.

### File List

- `_bmad-output/implementation-artifacts/3-3-integrate-neovim-installation-with-validation.md`
- `install.sh`
- `scripts/install-nvim.sh`
- `tests/install-nvim.sh`
