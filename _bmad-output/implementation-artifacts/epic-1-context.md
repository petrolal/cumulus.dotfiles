# Epic 1 Context: Scala Build Pipeline & Multi-Call CLI Dispatcher

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Establish the core Scala 3 build infrastructure using `sbt` and `sbt-native-image`, delivering a single compiled GraalVM Native Image executable (`cumulus`) that acts as a multi-call binary dispatcher for all desktop subcommands and symlinked aliases.

## Stories

- Story 1.1: sbt Project & GraalVM Native Image Build Scaffold
- Story 1.2: Multi-Call Binary Entrypoint & Symlink Dispatcher

## Requirements & Constraints

- **Single Native Executable**: Compile the entire application into a single standalone Linux ELF binary (`cumulus`) with zero JVM runtime dependencies on target machines.
- **Multi-Call Symlink Dispatching**: The executable must handle both umbrella invocations (`cumulus <cmd>`) and symlinked alias calls (`cumulus-<cmd> -> cumulus`).
- **Performance Envelope**: Maintain execution startup latency under 50 ms and peak RSS memory under 60 MB.
- **Zero-Reflection Serialization**: Ensure zero runtime reflection dependencies for GraalVM compatibility.

## Technical Decisions

- **Build Stack**: Scala 3.5.2, sbt 1.10.2, JDK 21 GraalVM Community Edition, `sbt-native-image` 0.5.0.
- **I/O & CLI Libraries**: `os-lib` (0.11.9-M8) for process/filesystem I/O, `uPickle` (4.4.3) for static JSON serialization, and `mainargs` (0.7.0) for CLI argument parsing.
- **Dispatch Pattern (AD-1 & AD-3)**: `cumulus.Main` reads `argv(0)` to detect `cumulus-<cmd>` execution or `argv(1)` for `cumulus <cmd>`, stripping prefixes and routing execution to module handlers with appropriate exit codes.

## Cross-Story Dependencies

- Story 1.1 provides the `sbt` build setup and native compilation capability required by Story 1.2.
- All subsequent epics (Epics 2-6) depend on the multi-call binary structure established in Epic 1.
