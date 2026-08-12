---
title: 'Epic 4: Sway Fibonacci Autotiling Daemon'
type: 'feature'
created: '2026-08-12'
status: 'done'
baseline_commit: '2afd37c'
review_loop_iteration: 0
context:
  - _bmad-output/implementation-artifacts/epic-4-context.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Sway window manager by default requires manual split toggling. We need an autotiling daemon (`cumulus autotiling`) that dynamically adjusts split direction to form a Fibonacci spiral layout.

**Approach:** Implement `AutotilingDaemon` in Scala 3 that inspects window dimensions and issues `swaymsg split v` / `swaymsg split h` commands on window focus events.

## Boundaries & Constraints

**Always:** Use `os-lib` process execution for `swaymsg` calls; check `SWAYSOCK` availability before starting.

**Ask First:** Modifying default split aspect ratio thresholds.

**Never:** Block or hang if `SWAYSOCK` is unavailable.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Wide Window Focus | Width > Height | Issues `swaymsg split h` | Handles swaymsg exit status |
| Tall Window Focus | Height >= Width | Issues `swaymsg split v` | Handles swaymsg exit status |
| No Sway Session | `SWAYSOCK` unset | Reports missing Sway socket and exits | Exit code 1 |

</frozen-after-approval>

## Code Map

- `src/main/scala/cumulus/dotfiles/autotiling/AutotilingDaemon.scala` -- Sway IPC autotiling daemon.
- `src/main/scala/cumulus/Main.scala` -- Connects `autotiling` subcommand to daemon handler.

## Tasks & Acceptance

**Execution:**
- [x] `src/main/scala/cumulus/dotfiles/autotiling/AutotilingDaemon.scala` -- Implement `AutotilingDaemon.run(ctx, args)` -- Autotiling daemon logic.
- [x] `src/main/scala/cumulus/Main.scala` -- Wire `autotiling` subcommand to `AutotilingDaemon.run` -- Dispatch integration.

**Acceptance Criteria:**
- Given Sway active with `SWAYSOCK` set, when executing `cumulus autotiling`, then window split orientation is updated dynamically based on window aspect ratio.

## Verification

**Commands:**
- `sbt compile` -- expected: SUCCESS_CRITERIA

## Suggested Review Order

**Sway Fibonacci Autotiling Daemon**

- Sway IPC event listener daemon and window dimension split logic
  [`AutotilingDaemon.scala:1`](../../src/main/scala/cumulus/dotfiles/autotiling/AutotilingDaemon.scala#L1)

- Main CLI dispatcher wiring for autotiling
  [`Main.scala:49`](../../src/main/scala/cumulus/Main.scala#L49)

