---
title: 'Epic 10: Bootstrap Script, CI Automation & Legacy Rust Decommissioning'
type: 'feature'
created: '2026-08-12'
status: 'done'
baseline_commit: 'fb9d801'
review_loop_iteration: 0
context:
  - _bmad-output/implementation-artifacts/epic-10-context.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `bootstrap.sh` needs to trigger Scala GraalVM `native-image` compilation, GitHub Actions CI needs setup, and legacy Rust files need decommissioning.

**Approach:** Update `bootstrap.sh`, add `.github/workflows/ci.yml`, and safely remove legacy Rust source files (`src/*.rs`, `Cargo.toml`, `Cargo.lock`, `tests/*.rs`).

## Boundaries & Constraints

**Always:** Ensure `bootstrap.sh` runs `sbt nativeImage`; `.github/workflows/ci.yml` runs `sbt test`.

**Ask First:** Removing non-Rust project documentation files.

**Never:** Leave dangling build references to `Cargo.toml`.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Bootstrap Install | `./bootstrap.sh` | Compiles Scala native binary & deploys symlinks | Reports missing sbt / GraalVM |
| CI Pipeline | GitHub Push | Runs `sbt compile nativeImage test` on GraalVM JDK 21 | Fails CI build on test error |

</frozen-after-approval>

## Code Map

- `bootstrap.sh` -- Updated installer bootstrap script for Scala + GraalVM.
- `.github/workflows/ci.yml` -- GitHub Actions GraalVM CI workflow.
- `src/*.rs` & `Cargo.toml` -- Legacy Rust files to remove.

## Tasks & Acceptance

**Execution:**
- [x] `bootstrap.sh` -- Update script to trigger sbt nativeImage & deployment -- Bootstrap installer update.
- [x] `.github/workflows/ci.yml` -- Create GitHub Actions CI workflow -- CI build automation.
- [x] Remove legacy Rust files (`src/*.rs`, `src/bin/*.rs`, `src/install/*.rs`, `Cargo.toml`, `Cargo.lock`, `tests/*.rs`, `.cumulus-sdd`) -- Rust decommissioning.

**Acceptance Criteria:**
- Given `bootstrap.sh`, when executed, then Scala native image compilation and deployment are triggered.
- Given the codebase, all legacy Rust files are removed, leaving a 100% Scala 3 repository.

## Verification

**Commands:**
- `sbt compile` -- expected: SUCCESS_CRITERIA

## Suggested Review Order

**Bootstrap Script, CI Automation & Legacy Rust Decommissioning**

- Updated bootstrap installer script
  [`bootstrap.sh:1`](../../bootstrap.sh#L1)

- GitHub Actions GraalVM CI workflow
  [`.github/workflows/ci.yml:1`](../../.github/workflows/ci.yml#L1)

