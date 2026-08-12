# Epic 9 Context: Comprehensive System Audit & MUnit Test Suite Migration

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Deliver 25+ point system diagnostic checks in `validate` and port all 8 Rust integration test files (`tests/*.rs`) into a Scala MUnit test suite (`src/test/scala/cumulus/`).

## Stories

- Story 9.1: Comprehensive System Audit & Diagnostics (`validate`)
- Story 9.2: MUnit Integration Test Suite Migration

## Requirements & Constraints

- **25+ Diagnostic Checkpoints**: Check config symlinks, binary availability, Waybar CSS, Kitty theme, Sway keybindings, JetBrainsMono font cache, and PATH paths.
- **MUnit Test Suite**: Add MUnit dependency (`"org.scalameta" %% "munit" % "1.0.0" % Test`) to `build.sbt` and implement test suites for all submodules (`ThemeSuite`, `ValidateSuite`, `MaintenanceSuite`, `InstallSuite`, `RefreshSuite`, `PickersSuite`, `SysUtilsSuite`, `SddSuite`).

## Technical Decisions

- MUnit test directory: `src/test/scala/cumulus/`.
- Test suites run via `sbt test`.
