---
title: 'Epic 2: Core System Context, Validation & Desktop Helpers'
type: 'feature'
created: '2026-08-12'
status: 'done'
baseline_commit: '41a60d0'
review_loop_iteration: 0
context:
  - _bmad-output/implementation-artifacts/epic-2-context.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** System health validation, AI development context generation, screen locking, idle management, and screenshot utilities are missing in the Scala codebase.

**Approach:** Implement `Validator`, `SpecDrivenDev`, and `SysUtils` modules in Scala 3 using `os-lib` process execution and file checks, connecting them to `cumulus.Main` dispatch.

## Boundaries & Constraints

**Always:** Use `os-lib` (`os.proc`, `os.exists`) for process spawning and path checks; print formatted status lines; return proper exit codes (0 for pass, non-zero for missing components).

**Ask First:** Changing subcommand arguments or screenshot output directories (`~/Pictures/Screenshots`).

**Never:** Modify user configuration files during read-only `validate` checks.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Validate Pass | All tools installed | Prints green `[OK]` badges for all components | Exit code 0 |
| Validate Missing Tool | Binary missing (e.g. `swaylock`) | Prints red `[FAIL]` badge with install tip | Exit code 1 |
| Lock Screen | `cumulus lock` | Spawns `swaylock` with theme colors | Returns swaylock exit code |
| Screenshot Region | `cumulus screenshot region` | Invokes `grim -g "$(slurp)"` to file | Reports capture failure if cancelled |

</frozen-after-approval>

## Code Map

- `src/main/scala/cumulus/dotfiles/validate/Validator.scala` -- Read-only health check validator.
- `src/main/scala/cumulus/dotfiles/sdd/SpecDrivenDev.scala` -- Token-efficient AI context generator.
- `src/main/scala/cumulus/dotfiles/sysutils/SysUtils.scala` -- Lock, idle, and screenshot desktop helpers.
- `src/main/scala/cumulus/Main.scala` -- Connects `validate`, `sdd`, `lock`, `idle`, `screenshot` dispatchers.

## Tasks & Acceptance

**Execution:**
- [x] `src/main/scala/cumulus/dotfiles/validate/Validator.scala` -- Implement `Validator.run(ctx, args)` -- Read-only health check.
- [x] `src/main/scala/cumulus/dotfiles/sdd/SpecDrivenDev.scala` -- Implement `SpecDrivenDev.run(ctx, args)` -- AI context generator.
- [x] `src/main/scala/cumulus/dotfiles/sysutils/SysUtils.scala` -- Implement `SysUtils.runLock`, `runIdle`, `runScreenshot` -- Desktop helpers.
- [x] `src/main/scala/cumulus/Main.scala` -- Wire `validate`, `sdd`, `lock`, `idle`, `screenshot` to real handlers -- Main dispatch integration.

**Acceptance Criteria:**
- Given a system with required tools installed, when executing `cumulus validate`, then all component health checks pass with exit code 0.
- Given Sway active, when executing `cumulus lock` or `cumulus screenshot`, then `swaylock` or `grim`/`slurp` are spawned via `os.proc`.

## Verification

**Commands:**
- `sbt compile` -- expected: SUCCESS_CRITERIA

## Suggested Review Order

**Core System Context, Validation & Desktop Helpers**

- Read-only health check validator
  [`Validator.scala:1`](../../src/main/scala/cumulus/dotfiles/validate/Validator.scala#L1)

- AI development context generator
  [`SpecDrivenDev.scala:1`](../../src/main/scala/cumulus/dotfiles/sdd/SpecDrivenDev.scala#L1)

- Screen locking, swayidle, and screenshot helpers
  [`SysUtils.scala:1`](../../src/main/scala/cumulus/dotfiles/sysutils/SysUtils.scala#L1)

- Main CLI dispatcher wiring
  [`Main.scala:37`](../../src/main/scala/cumulus/Main.scala#L37)

