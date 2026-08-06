---
story_key: 3-1-install-or-update-cumulus-neovim
epic: 3
story: 3.1
title: Install or Update Cumulus Neovim
status: review
---

# Story 3.1: Install or Update Cumulus Neovim

## Story

As a user installing the workstation,
I want `install.sh --nvim` to clone or update the canonical Cumulus Neovim
repository,
so that the editor is available without manual setup.

## Acceptance Criteria

1. Given the canonical repository is absent, when `install.sh --nvim` runs,
   then it clones `https://github.com/petrolal/cumulus.nvim.git` into the
   configured checkout directory.
2. Given the checkout already exists, when installation runs, then it verifies
   the expected `origin`, refuses uncommitted local changes, uses
   `git pull --ff-only`, and reports repository/network failures clearly.
3. Given `--dry-run` is supplied, when installation runs, then it prints the
   planned clone/update and deployment operations without creating directories,
   moving files, changing symlinks, pulling git data, or running validation.
4. Given the checkout is clean and the expected origin matches, when the
   installer is rerun, then the update and deployment are idempotent.
5. Given the checkout path exists but is not a git checkout, when installation
   runs, then it fails without replacing or deleting that path.

## Tasks / Subtasks

- [x] Audit and harden `scripts/install-nvim.sh` (AC: 1–5)
  - [x] Keep the canonical URL configurable only through the documented
    environment override while defaulting to the required GitHub repository.
  - [x] Preserve fast-forward-only updates and reject dirty or wrong-origin
    checkouts before mutation.
  - [x] Ensure all filesystem and git side effects flow through the dry-run
    command wrapper.
  - [x] Make backup directory creation collision-safe for repeated runs.
  - [x] Keep errors actionable and avoid destructive recovery behavior.
- [x] Verify integration with `install.sh --nvim` (AC: 1–4)
  - [x] Confirm dependency installation runs before repository/config deployment.
  - [x] Forward `--dry-run` and `--no-validate` consistently.
  - [x] Preserve the existing `--all-tools` auto-discovery behavior.
- [x] Add executable test coverage using temporary HOME and git repositories
  (AC: 1–5)
  - [x] Test initial clone and expected origin.
  - [x] Test clean fast-forward update.
  - [x] Test dirty checkout refusal and non-git path refusal.
  - [x] Test backup and idempotent correct-symlink deployment.
  - [x] Test dry-run leaves repository, config directory, backup directory,
    and symlink state unchanged.
- [x] Run repository validation (AC: 1–5)
  - [x] Run `bash -n install.sh scripts/install-nvim.sh`.
  - [x] Run installer dry-run checks.
  - [x] Run `git diff --check`.

## Dev Notes

### Existing implementation to extend

- `install.sh` parses `--nvim`, runs `scripts/install-nvim-deps.sh`, then runs
  `scripts/install-nvim.sh`.
- `install.sh` links every `scripts/*.sh` file to
  `~/.local/bin/cumulus-*`; do not add a second command-registration path.
- `scripts/install-nvim.sh` currently owns:
  - repository clone/update;
  - origin and dirty-checkout checks;
  - `~/.config/nvim` backup and symlink deployment;
  - optional headless validation.
- The canonical checkout defaults to `$HOME/cumulus.nvim` and may be overridden
  with `CUMULUS_NVIM_DIR`.
- The canonical URL defaults to
  `https://github.com/petrolal/cumulus.nvim.git` and may be overridden with
  `CUMULUS_NVIM_REPO_URL` for controlled testing or mirrors.

### Required safety behavior

- Use `set -euo pipefail`.
- Never delete or overwrite an existing non-git checkout.
- Never pull over uncommitted changes.
- Never replace a real Neovim configuration without moving it to the existing
  `~/.cumulus_backup/<timestamp>/` backup area.
- A correct existing symlink must remain untouched.
- Dry-run must be observational only; even parent-directory creation is a
  side effect and must be suppressed.
- Do not use destructive git commands or force updates.

### Repository and project patterns

- Resolve script location with:
  `SELF="$(readlink -f "${BASH_SOURCE[0]}")"`.
- Use the repository's logging and dry-run conventions.
- Do not introduce package dependencies or a new test framework. Tests may use
  Bash, temporary directories, git, and small command stubs.
- Keep the implementation compatible with Ubuntu/Debian and Arch targets.
- Do not modify generated theme files.

### Validation and integration constraints

- `install.sh --no-validate` must skip the Neovim headless validation invoked
  by `install-nvim.sh`, while normal `--nvim` runs validation when `nvim` is
  available.
- Missing optional Neovim tooling may produce a warning, but repository and
  deployment failures must remain fatal.
- A failed clone, origin check, pull, backup, or symlink operation must return
  a nonzero status with the affected path/operation in the message.
- Tests must assert filesystem state, not only log output.

### References

- [Source: docs/epics.md#Story 3.1: Install or Update Cumulus Neovim]
- [Source: docs/epics.md#Epic 3: Cumulus Neovim Installation]
- [Source: docs/architecture.md#Installer Flow (`install.sh`)]
- [Source: docs/architecture.md#Symlink-Sourced Configuration]
- [Source: project-context.md#Critical Implementation Rules]
- [Source: install.sh]
- [Source: scripts/install-nvim.sh]
- [Source: scripts/install-nvim-deps.sh]

## Dev Agent Record

### Agent Model Used

GPT-5.6 Luna

### Debug Log References

- Existing implementation was manually exercised with temporary git
  repositories, fake Neovim binaries, backup replacement, and dirty-checkout
  rejection.
- Adversarial review identified that `deploy_config()` creates the parent
  configuration directory during `--dry-run`; this must be fixed before the
  story is complete.
- The dry-run mutation was removed, backup directories now use collision-safe
  `mktemp` allocation, and `--no-validate` returns successfully when skipping
  headless validation.

### Completion Notes List

- Hardened clone/update/deployment safety and preserved canonical repository
  behavior.
- Added temporary-repository lifecycle tests covering clone, fast-forward
  update, backup, idempotency, refusal paths, dry-run immutability, and
  `--no-validate`.
- Validation passed: Bash syntax checks, installer dry-run integration,
  lifecycle tests, and `git diff --check`.

### File List

- `_bmad-output/implementation-artifacts/3-1-install-or-update-cumulus-neovim.md`
- `scripts/install-nvim.sh`
- `install.sh`
- `tests/install-nvim.sh`

