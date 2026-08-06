---
story_key: 3-2-deploy-the-neovim-configuration-safely
epic: 3
story: 3.2
title: Deploy the Neovim Configuration Safely
status: review
---

# Story 3.2: Deploy the Neovim Configuration Safely

## Story

As a user with an existing Neovim setup,
I want real configuration files backed up before Cumulus is linked,
so that installation never destroys my current setup.

## Acceptance Criteria

1. Given `~/.config/nvim` is a real file or directory, when deployment starts,
   then it is moved into a unique timestamped Cumulus backup directory before
   the repository symlink is created.
2. Given `~/.config/nvim` is already a symlink to the selected checkout, when
   deployment starts, then no replacement or backup occurs.
3. Given `~/.config/nvim` is a symlink to another target, when deployment
   starts, then the existing symlink is backed up rather than followed or
   deleted.
4. Given the destination parent directory is absent, when normal installation
   runs, then it creates only the required parent directories.
5. Given `--dry-run` is supplied, when deployment runs, then no parent
   directory, backup, move, or symlink is created.

## Tasks / Subtasks

- [x] Harden `deploy_config()` in `scripts/install-nvim.sh` (AC: 1–5)
  - [x] Preserve correct-symlink idempotency.
  - [x] Back up files, directories, and symlinks with `mv`.
  - [x] Allocate collision-safe backup directories.
  - [x] Keep dry-run completely side-effect-free.
- [x] Add deployment lifecycle tests (AC: 1–5)
  - [x] Test real file and real directory backups.
  - [x] Test correct and incorrect symlink handling.
  - [x] Test unique backup paths across repeated runs.
  - [x] Test absent parent directories in normal and dry-run modes.
- [x] Run `bash -n scripts/install-nvim.sh`, lifecycle tests, and
  `git diff --check` (AC: 1–5).

## Dev Notes

- Extend `scripts/install-nvim.sh`; do not create a second Neovim deployment
  mechanism.
- Existing backups belong under `$HOME/.cumulus_backup/`.
- The repository uses symlink deployment as its source-of-truth model.
- Never use `rm -rf`, `git reset`, or forced replacement for user config.
- The dry-run command wrapper must cover all mutations, including parent
  directory creation.
- Tests should use temporary HOME directories and must assert filesystem state.

### References

- [Source: docs/epics.md#Story 3.2: Deploy the Neovim Configuration Safely]
- [Source: docs/architecture.md#Symlink-Sourced Configuration]
- [Source: install.sh]
- [Source: scripts/install-nvim.sh]
- [Source: _bmad-output/implementation-artifacts/3-1-install-or-update-cumulus-neovim.md]
- [Source: project-context.md#Critical Implementation Rules]

## Dev Agent Record

### Agent Model Used

GPT-5.6 Luna

### Debug Log References

- Story 3.1 established temporary-HOME lifecycle testing and collision-safe
  backup allocation patterns.

### Completion Notes List

- Verified safe deployment for real files, directories, correct symlinks, and
  wrong-target symlinks.
- Verified unique backups, parent-directory creation, dry-run immutability, and
  idempotent relinking.
- Validation passed: Bash syntax checks, lifecycle tests, and `git diff --check`.

### File List

- `_bmad-output/implementation-artifacts/3-2-deploy-the-neovim-configuration-safely.md`
- `scripts/install-nvim.sh`
- `tests/install-nvim.sh`
