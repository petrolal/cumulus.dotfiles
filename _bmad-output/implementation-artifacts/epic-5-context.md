# Epic 5 Context: Maintenance & Backup Suite

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Deliver system maintenance and dotfiles snapshot utilities: config archive creation (`backup`), snapshot restoration (`restore`), and git pull dotfiles updates (`update`).

## Stories

- Story 5.1: Configuration Snapshot Backup & Restore (`backup`, `restore`)
- Story 5.2: Dotfiles Git Update & Installer Trigger (`update`)

## Requirements & Constraints

- **Snapshot Archiving**: Compress dotfiles configs in `~/.config/` into timestamped `.tar.gz` files stored in `~/.local/share/cumulus/backups/`.
- **Snapshot Restoration**: Safely extract `.tar.gz` snapshots to restore dotfiles configuration state.
- **Automated Update**: Run `git pull --rebase` on the dotfiles repository via `os-lib` and trigger installer redeployment.

## Technical Decisions

- Module: `cumulus.dotfiles.maintenance.Maintenance`.
- Use `os-lib` (`os.proc`, `os.makeDir`, `os.list`) for tarball operations and git commands.
