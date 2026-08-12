---
title: 'Epic 5: Maintenance & Backup Suite'
type: 'feature'
created: '2026-08-12'
status: 'done'
baseline_commit: '63a70e9'
review_loop_iteration: 0
context:
  - _bmad-output/implementation-artifacts/epic-5-context.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** System configuration archiving (`backup`), snapshot restoration (`restore`), and dotfiles git updates (`update`) are missing in the Scala codebase.

**Approach:** Implement `Maintenance` in Scala 3 using `os-lib` to create/restore `.tar.gz` snapshots and execute `git pull --rebase`.

## Boundaries & Constraints

**Always:** Save backups under `~/.local/share/cumulus/backups/`; use `os.proc` for tar and git commands.

**Ask First:** Overwriting existing backups without timestamp suffixes.

**Never:** Delete user config files without creating a backup snapshot first.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Backup Configs | `cumulus backup` | Creates `.tar.gz` in `~/.local/share/cumulus/backups/` | Reports archive write failure |
| Restore Archive | `cumulus restore <tarball>` | Extracts tarball to restore config state | Reports non-existent archive |
| Git Update | `cumulus update` | Runs `git pull --rebase` in dotfiles directory | Reports git rebase/merge conflicts |

</frozen-after-approval>

## Code Map

- `src/main/scala/cumulus/dotfiles/maintenance/Maintenance.scala` -- Maintenance, backup, restore, and update suite.
- `src/main/scala/cumulus/Main.scala` -- Connects `backup`, `restore`, `update` subcommands.

## Tasks & Acceptance

**Execution:**
- [x] `src/main/scala/cumulus/dotfiles/maintenance/Maintenance.scala` -- Implement `Maintenance.runBackup`, `runRestore`, `runUpdate` -- Maintenance suite.
- [x] `src/main/scala/cumulus/Main.scala` -- Wire `backup`, `restore`, `update` subcommands to `Maintenance` handlers -- Dispatch integration.

**Acceptance Criteria:**
- Given dotfiles configs, when executing `cumulus backup`, then a timestamped `.tar.gz` is saved to `~/.local/share/cumulus/backups/`.
- Given `cumulus update`, when executed, then `git pull --rebase` is executed via `os-lib`.

## Verification

**Commands:**
- `sbt compile` -- expected: SUCCESS_CRITERIA

## Suggested Review Order

**Maintenance & Backup Suite**

- Config snapshot tarball archiving, restore, and git update handlers
  [`Maintenance.scala:1`](../../src/main/scala/cumulus/dotfiles/maintenance/Maintenance.scala#L1)

- Main CLI dispatcher wiring for maintenance subcommands
  [`Main.scala:52`](../../src/main/scala/cumulus/Main.scala#L52)

