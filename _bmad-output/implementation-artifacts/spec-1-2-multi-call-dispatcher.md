---
title: 'Story 1.2: Multi-Call Binary Entrypoint & Symlink Dispatcher'
type: 'feature'
created: '2026-08-12'
status: 'done'
baseline_commit: 'ee09f50'
review_loop_iteration: 0
context:
  - _bmad-output/implementation-artifacts/epic-1-context.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The `cumulus` binary needs to support multi-call execution (e.g. running via a `cumulus-autotiling` or `cumulus-theme` symlink vs umbrella `cumulus <cmd>`), resolving system context and routing to submodule handlers with proper exit codes.

**Approach:** Implement `CumulusError`, `Context` environment resolution, and `cumulus.Main` dispatch logic that checks `argv(0)` or `argv(1)` to strip `cumulus-` prefixes and route execution.

## Boundaries & Constraints

**Always:** Use `os-lib` (`os.Path`, `os.home`, `os.env`) for environment discovery and handle exit codes cleanly (0 for success, non-zero for error).

**Ask First:** Changing subcommand names or CLI umbrella help format.

**Never:** Use reflection for subcommand routing or swallow exceptions silently.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Umbrella Help | `cumulus` (no args) | Displays umbrella usage help text | Exit code 0 |
| Symlink Dispatch | `cumulus-autotiling` | Resolves subcommand to `autotiling` | Returns subcommand status code |
| Umbrella Dispatch | `cumulus theme catppuccin-mocha` | Resolves subcommand `theme` with `["catppuccin-mocha"]` | Returns subcommand status code |
| Unknown Command | `cumulus unknown-cmd` | Prints red error message detailing unknown command | Exit code 1 |

</frozen-after-approval>

## Code Map

- `src/main/scala/cumulus/dotfiles/error/CumulusError.scala` -- Error domain definition with exit code mapping.
- `src/main/scala/cumulus/dotfiles/context/Context.scala` -- XDG paths and Sway environment discovery.
- `src/main/scala/cumulus/Main.scala` -- Multi-call binary dispatcher inspecting `argv(0)` / `argv(1)`.

## Tasks & Acceptance

**Execution:**
- [x] `src/main/scala/cumulus/dotfiles/error/CumulusError.scala` -- Implement `CumulusError` sealed hierarchy -- Error domain.
- [x] `src/main/scala/cumulus/dotfiles/context/Context.scala` -- Implement `Context` case class and `Context.discover()` -- Environment context discovery.
- [x] `src/main/scala/cumulus/Main.scala` -- Implement `main(args: Array[String])` dispatching on `argv(0)` or `argv(1)` -- Multi-call entrypoint dispatcher.

**Acceptance Criteria:**
- Given a symlink `cumulus-autotiling -> cumulus` or umbrella invocation `cumulus autotiling`, when executed, then `cumulus.Main` correctly extracts subcommand `autotiling` and invokes its handler.

## Design Notes

```scala
package cumulus

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.CumulusError

object Main:
  def main(args: Array[String]): Unit =
    val exitCode = dispatch(args)
    if exitCode != 0 then sys.exit(exitCode)

  def dispatch(args: Array[String]): Int =
    val prog = sys.env.getOrElse("CUMULUS_PROG_NAME", "")
    val (cmd, rest) = resolveCommand(prog, args)
    // Dispatch to registered submodules...
```

## Verification

**Commands:**
- `sbt compile` -- expected: SUCCESS_CRITERIA

## Suggested Review Order

**Multi-Call Dispatcher & Environment Resolution**

- Multi-call binary entrypoint inspecting `argv(0)` / `argv(1)`
  [`Main.scala:1`](../../src/main/scala/cumulus/Main.scala#L1)

- Environment and XDG paths discovery
  [`Context.scala:1`](../../src/main/scala/cumulus/dotfiles/context/Context.scala#L1)

- Error domain sealed hierarchy
  [`CumulusError.scala:1`](../../src/main/scala/cumulus/dotfiles/error/CumulusError.scala#L1)

