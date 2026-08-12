---
title: 'Story 1.1: sbt Project & GraalVM Native Image Build Scaffold'
type: 'feature'
created: '2026-08-12'
status: 'done'
baseline_commit: '45ada12551549c9381418f4e63c74f2c9ee38153'
review_loop_iteration: 0
context:
  - _bmad-output/implementation-artifacts/epic-1-context.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The `cumulus.dotfiles` codebase currently relies on Rust/Cargo (`Cargo.toml`). To migrate to Scala 3 with GraalVM Native Image, we need a root `sbt` build setup that compiles a single native binary without JVM runtime dependencies.

**Approach:** Initialize a Scala 3.5.2 `sbt` project with `sbt-native-image` plugin (0.5.0), configure dependencies (`os-lib`, `uPickle`, `mainargs`), and add a minimal `cumulus.Main` entrypoint.

## Boundaries & Constraints

**Always:** Use Scala 3.5.2, `sbt` 1.10.2, `sbt-native-image` 0.5.0, `os-lib` 0.11.9-M8, `uPickle` 4.4.3, and `mainargs` 0.7.0.

**Ask First:** Changing dependency versions or splitting into multiple sbt subprojects.

**Never:** Use heavy reflective JSON frameworks (e.g. Jackson) or introduce JVM runtime requirements for release binaries.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| SBT Compile | `sbt compile` | Clean Scala 3 compilation of `cumulus.Main` | Reports sbt syntax or dependency resolution errors |
| Native Image Build | `sbt nativeImage` | Target ELF binary generated at `target/native-image/cumulus` | Non-zero exit code if GraalVM `native-image` missing |

</frozen-after-approval>

## Code Map

- `build.sbt` -- Main sbt build definition configuring Scala 3.5.2, NativeImagePlugin, and dependencies (`os-lib`, `upickle`, `mainargs`).
- `project/build.properties` -- Pins sbt version to 1.10.2.
- `project/plugins.sbt` -- Enables `sbt-native-image` plugin v0.5.0.
- `src/main/scala/cumulus/Main.scala` -- Root executable main class for multi-call binary entrypoint.

## Tasks & Acceptance

**Execution:**
- [x] `build.sbt` -- Define Scala 3.5.2 build with NativeImagePlugin, application name `cumulus`, and libraries `os-lib`, `upickle`, `mainargs` -- Root build manifest.
- [x] `project/build.properties` -- Set `sbt.version=1.10.2` -- Lock sbt version.
- [x] `project/plugins.sbt` -- Add `sbt-native-image` plugin `0.5.0` -- Enable GraalVM native binary task.
- [x] `src/main/scala/cumulus/Main.scala` -- Implement initial `@main def main(args: Array[String]): Unit` stub entrypoint -- Native executable entrypoint.

**Acceptance Criteria:**
- Given an sbt build setup configured with Scala 3.5.2 and sbt-native-image 0.5.0, when executing `sbt compile`, then all Scala sources compile with zero warnings or errors.

## Design Notes

```scala
// build.sbt design structure
enablePlugins(NativeImagePlugin)

scalaVersion := "3.5.2"
name := "cumulus"

libraryDependencies ++= Seq(
  "com.lihaoyi" %% "os-lib" % "0.11.9-M8",
  "com.lihaoyi" %% "upickle" % "4.4.3",
  "com.lihaoyi" %% "mainargs" % "0.7.0"
)

Compile / mainClass := Some("cumulus.Main")
nativeImageOptions ++= Seq("--no-fallback", "-H:+ReportExceptionStackTraces")
```

## Verification

**Commands:**
- `sbt compile` -- expected: SUCCESS_CRITERIA

## Suggested Review Order

**Scala 3 & GraalVM Build Pipeline**

- Root entrypoint stub for multi-call binary dispatch
  [`Main.scala:1`](../../src/main/scala/cumulus/Main.scala#L1)

- sbt build manifest configuring Scala 3.5.2, sbt-native-image 0.5.0, os-lib, upickle, mainargs
  [`build.sbt:1`](../../build.sbt#L1)

- sbt version lock (1.10.2)
  [`build.properties:1`](../../project/build.properties#L1)

- sbt-native-image plugin registration (0.5.0)
  [`plugins.sbt:1`](../../project/plugins.sbt#L1)
