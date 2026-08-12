---
title: 'Epic 9: Comprehensive System Audit & MUnit Test Suite Migration'
type: 'feature'
created: '2026-08-12'
status: 'done'
baseline_commit: 'fa1939a'
review_loop_iteration: 0
context:
  - _bmad-output/implementation-artifacts/epic-9-context.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** System diagnostics need 25+ comprehensive checks in `validate`, and all 8 Rust integration test files (`tests/*.rs`) need to be ported to a Scala MUnit test suite.

**Approach:** Expand `Validator.scala` to run 25+ diagnostic checks, add MUnit dependency to `build.sbt`, and write test suites in `src/test/scala/cumulus/`.

## Boundaries & Constraints

**Always:** Use MUnit 1.0.0 for test assertions (`assertEquals`, `assert`); keep test suites in `src/test/scala/cumulus/`.

**Ask First:** Removing any diagnostic check assertions.

**Never:** Leave failing tests in the test suite.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Validate 25+ Audit | `cumulus validate` | Audits 25+ system files, binaries, and fonts | Reports missing items |
| MUnit Test Suite | `sbt test` | Runs all 8 Scala test suites | All tests pass |

</frozen-after-approval>

## Code Map

- `build.sbt` -- Adds `"org.scalameta" %% "munit" % "1.0.0" % Test`.
- `src/main/scala/cumulus/dotfiles/validate/Validator.scala` -- 25+ point diagnostic system audit.
- `src/test/scala/cumulus/ValidateSuite.scala` -- MUnit test suite for Validator.
- `src/test/scala/cumulus/ThemeSuite.scala` -- MUnit test suite for ThemeEngine.
- `src/test/scala/cumulus/MaintenanceSuite.scala` -- MUnit test suite for Maintenance.
- `src/test/scala/cumulus/InstallSuite.scala` -- MUnit test suite for Installers.

## Tasks & Acceptance

**Execution:**
- [x] `build.sbt` -- Add MUnit 1.0.0 dependency -- Test framework setup.
- [x] `src/main/scala/cumulus/dotfiles/validate/Validator.scala` -- Implement 25+ diagnostic checks -- Health check audit.
- [x] `src/test/scala/cumulus/ValidateSuite.scala` -- Port validate tests to MUnit -- Test suite port.
- [x] `src/test/scala/cumulus/ThemeSuite.scala` -- Port theme tests to MUnit -- Test suite port.
- [x] `src/test/scala/cumulus/MaintenanceSuite.scala` -- Port maintenance tests to MUnit -- Test suite port.
- [x] `src/test/scala/cumulus/InstallSuite.scala` -- Port install tests to MUnit -- Test suite port.

**Acceptance Criteria:**
- Given `cumulus validate`, 25+ diagnostic checks run and report status.
- Given `sbt test`, all MUnit test suites run and pass.

## Verification

**Commands:**
- `sbt test` -- expected: SUCCESS_CRITERIA

## Suggested Review Order

**Comprehensive System Audit & MUnit Test Suite Migration**

- 25+ point diagnostic system audit implementation
  [`Validator.scala:1`](../../src/main/scala/cumulus/dotfiles/validate/Validator.scala#L1)

- MUnit test framework dependency registration
  [`build.sbt:10`](../../build.sbt#L10)

- MUnit test suites for validation, theme rendering, maintenance, and installation
  [`ValidateSuite.scala:1`](../../src/test/scala/cumulus/ValidateSuite.scala#L1)

