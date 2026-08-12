# Epic 10 Context: Bootstrap Script, CI Automation & Legacy Rust Decommissioning

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Update `bootstrap.sh` to trigger Scala GraalVM `native-image` compilation (`sbt nativeImage`), create GitHub Actions CI workflow (`.github/workflows/ci.yml`), and safely decommission/remove legacy Rust source files (`src/*.rs`, `Cargo.toml`, `Cargo.lock`, `tests/*.rs`).

## Stories

- Story 10.1: Bootstrap Installer & GitHub Actions GraalVM CI Workflow
- Story 10.2: Legacy Rust Codebase Decommissioning

## Requirements & Constraints

- **Bootstrap Update**: `bootstrap.sh` runs `sbt nativeImage` (or installs the Scala binary) and triggers deployment.
- **GitHub Actions CI Workflow**: Set up `.github/workflows/ci.yml` with GraalVM JDK 21 setup and `sbt compile nativeImage test`.
- **Rust Decommissioning**: Remove legacy Rust files (`src/*.rs`, `src/bin/*.rs`, `src/install/*.rs`, `Cargo.toml`, `Cargo.lock`, `tests/*.rs`, `.cumulus-sdd`).

## Technical Decisions

- GitHub Actions workflow uses `graalvm/setup-graalvm@v1` with java-version `21`.
- Clean workspace after Rust removal so repository is 100% Scala 3.
