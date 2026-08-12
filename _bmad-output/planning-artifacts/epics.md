---
stepsCompleted: [1, 2, 3, 4]
inputDocuments:
  - _bmad-output/planning-artifacts/architecture/architecture-cumulus.dotfiles-2026-08-12/ARCHITECTURE-SPINE.md
  - Cargo.toml
  - src/lib.rs
  - docs/migration-rust-to-scala.md
---

# cumulus.dotfiles Scala Migration - Complete Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for the cumulus.dotfiles Scala migration, decomposing both Phase 1 (Core Scaffold & Subcommands) and Phase 2 (Deep Implementation, MUnit Testing & Rust Decommissioning) into implementable user stories.

## Requirements Inventory

### Functional Requirements

- **FR1: Umbrella CLI & Symlink Dispatcher**: The `cumulus` umbrella binary must inspect `argv(0)` or `argv(1)` to resolve `cumulus-<command>` symlinks or `cumulus <command>` invocations, executing the targeted Scala submodule and mapping exit codes.
- **FR2: Desktop Theme Engine**: Select and apply desktop theme flavors and wallpaper background modes live across Sway, Waybar, Kitty, Wofi, Neovim, GTK, Swaylock, and OpenRGB (`cumulus theme`).
- **FR3: Runtime Refresh Engine**: Trigger live refresh for running desktop apps (`runtime-refresh`), synchronize GNOME/GTK dark/light color scheme preference (`os-colorscheme`), and update hardware RGB lighting color (`rgb-theme`).
- **FR4: Sway Autotiling Daemon**: Run Fibonacci spiral layout autotiling logic in response to Sway IPC window focus/creation events (`autotiling`).
- **FR5: System Desktop Helpers**: Screen lock using active theme styles (`lock`), daemon auto-lock/DPMS management (`idle`), and display screen capture (`screenshot`).
- **FR6: System Validation & Health Check**: Run read-only health checks on desktop config files, binaries, environment variables, and font installations (`validate`).
- **FR7: Maintenance & Backup Suite**: Snapshot dotfiles configs into timestamped archives (`backup`), restore snapshots (`restore`), and pull/re-install dotfiles updates (`update`).
- **FR8: Spec-Driven Development Context**: Generate token-efficient AI context and system specifications for development workflows (`sdd`).
- **FR9: Graphical Wofi Pickers**: Provide Wofi GUI launcher interfaces for theme switching (`theme-picker`) and live Sway keybindings cheatsheet (`whichkey`).
- **FR10: Automated Installer Suite**: Execute machine setup deployments (`install`/`deploy`), JetBrainsMono font installation (`install-fonts`), desktop core applications (`install-apps`), web browser (`install-browser`), DevOps tools (`install-devops`), Zsh environment (`install-zsh`), SDKMAN! (`install-sdkman`), and Neovim dependencies (`install-nvim`, `install-nvim-deps`).
- **FR11: Deep Manifest & Symlink Engine**: Port `.dotfiles_manifest` tracking, pre-dotfiles configuration backups, and XDG symlink deployment from `src/install/deploy.rs` to `DeployInstaller.scala`.
- **FR12: Comprehensive Tooling & Dependency Provisioners**: Implement deep package manager integration (`pacman`, `dnf`, `apt`, `brew`) and binary installation rules for apps, browser, devops, fonts, zsh, sdkman, and nvim dependencies in `ToolInstallers.scala`.
- **FR13: Theme Palette & Template Rendering**: Port full color palette parsing and template rendering into Kitty (`kitty.conf`), Waybar (`style.css`), Wofi (`wofi.css`), and Swaylock colors in `ThemeEngine.scala`.
- **FR14: Sway IPC Multi-Monitor Event Loop**: Expand Sway Unix socket event loop to handle multi-monitor displays, workspace splits, and floating window exclusions in `AutotilingDaemon.scala`.
- **FR15: Comprehensive Read-Only System Audit**: Expand `Validator.scala` to audit 25+ specific config file paths, GTK theme integrity, Nerd Font family validity, and PATH environment variables.
- **FR16: Scala MUnit Integration Test Suite**: Port all 8 Rust integration test files (`tests/*.rs`) into a comprehensive MUnit test suite in `src/test/scala/cumulus/` (`ThemeSuite`, `ValidateSuite`, `MaintenanceSuite`, `InstallSuite`, `RefreshSuite`, `PickersSuite`, `SysUtilsSuite`, `SddSuite`).
- **FR17: Bootstrap Script & CI Pipeline Update**: Update `bootstrap.sh` and add GitHub Actions CI workflow for GraalVM `native-image` compilation (`sbt nativeImage`).
- **FR18: Legacy Rust Stack Decommissioning**: Cleanly remove legacy Rust source files (`src/*.rs`), manifests (`Cargo.toml`, `Cargo.lock`), and Rust tests (`tests/*.rs`) once GraalVM native binary is fully verified.

### NonFunctional Requirements

- **NFR1: GraalVM AOT Native Compilation**: Compile the entire Scala codebase into a single standalone native Linux ELF executable (`cumulus`) using GraalVM `native-image` and `sbt-native-image` 0.5.0 with zero JVM runtime dependencies on target systems.
- **NFR2: Low Execution Latency**: Maintain CLI startup and execution latency within 15–50 ms across subcommands.
- **NFR3: Memory Efficiency**: Maintain baseline execution RSS memory footprint under 60 MB.
- **NFR4: Zero Reflection Serialization**: All JSON config parsing and generation must use compile-time derived `uPickle` macros to prevent GraalVM reflection configuration overhead.
- **NFR5: 100% Test Parity**: All 8 test suites pass cleanly with `sbt test`.
- **NFR6: Build Automation**: GraalVM Native Image compilation runs cleanly via `sbt nativeImage`.

### Additional Requirements

- **AD-1 (Single Multi-Call Binary)**: Build 1 single executable `cumulus` and set up symlinks (`cumulus-<cmd> -> cumulus`) during installation to prevent multi-target GraalVM build time multiplication.
- **AD-2 (Non-Reflective I/O)**: Use `os-lib` (`0.11.9-M8`) for all file/process operations and `uPickle` (`4.4.3`) for JSON.
- **AD-3 (CLI Dispatch Routing)**: Implement `cumulus.Main` with `mainargs` (`0.7.0`) for flag parsing and sub-command routing.
- **AD-4 (Streamed Process Execution)**: Stream stdout/stderr for subprocess invocations (`swaymsg`, `wofi`, `pactl`) to avoid memory buffering.

### UX Design Requirements

*(N/A - Desktop CLI and Wofi GUI pickers follow existing Sway/Wofi themes)*

### FR Coverage Map

- **FR1 (Umbrella CLI & Symlink Dispatcher)**: Epic 1 (Story 1.1, Story 1.2) [COMPLETE]
- **FR2 (Desktop Theme Engine)**: Epic 3 (Story 3.1) [COMPLETE]
- **FR3 (Runtime Refresh Engine & Color Sync)**: Epic 3 (Story 3.2) [COMPLETE]
- **FR4 (Sway Autotiling Daemon)**: Epic 4 (Story 4.1) [COMPLETE]
- **FR5 (System Desktop Helpers)**: Epic 2 (Story 2.4) [COMPLETE]
- **FR6 (System Validation & Health Check)**: Epic 2 (Story 2.2) [COMPLETE]
- **FR7 (Maintenance & Backup Suite)**: Epic 5 (Story 5.1, Story 5.2) [COMPLETE]
- **FR8 (Spec-Driven Development Context)**: Epic 2 (Story 2.3) [COMPLETE]
- **FR9 (Graphical Wofi Pickers)**: Epic 3 (Story 3.3) [COMPLETE]
- **FR10 (Automated Installer Suite)**: Epic 6 (Story 6.1, Story 6.2) [COMPLETE]
- **FR11 (Deep Manifest & Symlink Engine)**: Epic 7 (Story 7.1)
- **FR12 (Comprehensive Tooling Provisioners)**: Epic 7 (Story 7.2)
- **FR13 (Theme Palette & Template Rendering)**: Epic 8 (Story 8.1)
- **FR14 (Sway IPC Multi-Monitor Event Loop)**: Epic 8 (Story 8.2)
- **FR15 (Comprehensive Read-Only System Audit)**: Epic 9 (Story 9.1)
- **FR16 (Scala MUnit Integration Test Suite)**: Epic 9 (Story 9.2)
- **FR17 (Bootstrap Script & CI Pipeline Update)**: Epic 10 (Story 10.1)
- **FR18 (Legacy Rust Stack Decommissioning)**: Epic 10 (Story 10.2)

---

## Epic List

### Phase 1 Epics (Completed)

- **Epic 1: Scala Build Pipeline & Multi-Call CLI Dispatcher** [COMPLETE - Commit `41a60d0`]
- **Epic 2: Core System Context, Validation & Desktop Helpers** [COMPLETE - Commit `f93bd14`]
- **Epic 3: Live Theme Engine, Color Sync & Wofi Pickers** [COMPLETE - Commit `2afd37c`]
- **Epic 4: Sway Fibonacci Autotiling Daemon** [COMPLETE - Commit `63a70e9`]
- **Epic 5: Maintenance & Backup Suite** [COMPLETE - Commit `b3f20bd`]
- **Epic 6: Automated Installer & Environment Provisioning Suite** [COMPLETE - Commit `7af5ea1`]

---

### Phase 2 Epics (Remaining Migration & Rust Decommissioning)

### Epic 7: Deep Installer Engine, Manifest Tracking & Tooling Provisioners
Expand machine deployment with `.dotfiles_manifest` tracking, pre-dotfiles config backup preservation, and deep package manager integration (`pacman`, `dnf`, `apt`, `brew`) for core apps, browser, devops tools, zsh, sdkman, and neovim dependencies.
**FRs covered:** FR11, FR12

#### Story 7.1: Dotfiles Manifest Tracking & Deployment Engine

As an installer user,
I want `cumulus install` to generate a `.dotfiles_manifest` and safely backup existing pre-dotfiles configs,
So that deploying cumulus.dotfiles never overwrites custom user configs unrecoverably.

**Acceptance Criteria:**

**Given** existing user configuration files in `~/.config/`
**When** executing `cumulus install`
**Then** pre-existing files are safely copied to `~/.config/*.bak`
**And** a `.dotfiles_manifest` JSON tracking file is saved to `~/.local/share/cumulus/manifest.json`.

#### Story 7.2: Comprehensive Tooling & Package Manager Provisioners

As a developer,
I want `cumulus install-apps`, `install-browser`, `install-devops`, `install-zsh`, `install-sdkman`, and `install-nvim-deps` to detect the system package manager,
So that required CLI/GUI tools and developer dependencies are automatically installed across Arch, Fedora, and Debian/Ubuntu systems.

**Acceptance Criteria:**

**Given** a target system running Arch Linux (`pacman`) or Fedora (`dnf`)
**When** executing `cumulus install-devops` or `cumulus install-nvim-deps`
**Then** the installer detects the active package manager and executes the corresponding non-interactive installation commands via `os-lib`.

---

### Epic 8: Theme Template Rendering & Sway IPC Multi-Monitor Autotiling
Expand theme switching to parse full color palette themes and render templates into Kitty, Waybar, Wofi, and Swaylock configuration files, and expand the autotiling daemon for multi-monitor displays.
**FRs covered:** FR13, FR14

#### Story 8.1: Color Palette Parser & Template Rendering Engine

As a desktop user,
I want `cumulus theme <flavor>` to parse palette definition files and dynamically render Kitty, Waybar, Wofi, and Swaylock config files,
So that all application themes change cohesively without manual config edits.

**Acceptance Criteria:**

**Given** a theme palette JSON/TOML definition (e.g. `catppuccin-mocha`)
**When** executing `cumulus theme catppuccin-mocha`
**Then** color templates for Kitty (`kitty.conf`), Waybar (`style.css`), Wofi (`wofi.css`), and Swaylock are generated and written to `~/.config/` via `os-lib`.

#### Story 8.2: Multi-Monitor & Floating Window Autotiling Event Loop

As a Sway desktop user,
I want `cumulus autotiling` to handle multi-monitor output displays and ignore floating windows,
So that dynamic Fibonacci splitting applies strictly to tiled windows on each active monitor.

**Acceptance Criteria:**

**Given** a multi-monitor Sway desktop session with floating windows open
**When** new tiled windows are focused on any output display
**Then** `AutotilingDaemon` filters out floating nodes and issues the correct split orientation (`split h` or `split v`) per monitor output.

---

### Epic 9: Comprehensive System Audit & MUnit Test Suite Migration
Expand system health validation to audit 25+ specific configuration files, fonts, and environment paths, and port all 8 Rust integration test files into a Scala MUnit test suite.
**FRs covered:** FR15, FR16

#### Story 9.1: Comprehensive System Audit & Diagnostics (`validate`)

As a system administrator,
I want `cumulus validate` to perform a 25+ point diagnostic check on dotfile symlinks, GTK themes, font family validity, and PATH environment variables,
So that I can immediately detect broken symlinks or missing desktop components.

**Acceptance Criteria:**

**Given** a deployed `cumulus.dotfiles` setup
**When** executing `cumulus validate`
**Then** it verifies 25+ diagnostic check points (Waybar CSS, Kitty config, Sway keybindings, JetBrainsMono font cache, PATH paths) and outputs colorized pass/fail badges.

#### Story 9.2: MUnit Integration Test Suite Migration

As a developer,
I want a comprehensive MUnit test suite in `src/test/scala/cumulus/` covering all modules (`ThemeSuite`, `ValidateSuite`, `MaintenanceSuite`, `InstallSuite`, `RefreshSuite`, `PickersSuite`, `SysUtilsSuite`, `SddSuite`),
So that I can verify feature parity with `sbt test`.

**Acceptance Criteria:**

**Given** the MUnit testing library added to `build.sbt`
**When** executing `sbt test`
**Then** all 8 test suites pass 100% cleanly without errors.

---

### Epic 10: Bootstrap Script, CI Automation & Legacy Rust Decommissioning
Update `bootstrap.sh` for GraalVM `native-image` installation, create GitHub Actions CI workflow, and remove legacy Rust source files once GraalVM native binary is fully verified.
**FRs covered:** FR17, FR18

#### Story 10.1: Bootstrap Installer & GitHub Actions GraalVM CI Workflow

As a maintainer,
I want `bootstrap.sh` updated and a `.github/workflows/ci.yml` added,
So that `cumulus` is compiled via `sbt nativeImage` automatically in CI and installed on target systems.

**Acceptance Criteria:**

**Given** a GitHub push or fresh machine setup
**When** `bootstrap.sh` runs or CI workflow triggers
**Then** `sbt nativeImage` compiles the native binary `cumulus` and deploys it to `~/.local/bin/`.

#### Story 10.2: Legacy Rust Codebase Decommissioning

As a maintainer,
I want legacy Rust source files (`src/*.rs`), manifests (`Cargo.toml`, `Cargo.lock`), and Rust tests (`tests/*.rs`) safely deleted,
So that the repository remains 100% clean and Scala-based.

**Acceptance Criteria:**

**Given** the Scala GraalVM native binary verified on target systems
**When** executing the decommissioning task
**Then** all legacy Rust files (`src/*.rs`, `Cargo.toml`, `Cargo.lock`, `tests/*.rs`) are removed from the repository.
