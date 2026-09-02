---
stepsCompleted: ["step-01", "step-02", "step-03", "step-04"]
inputDocuments: [
  "_bmad-output/planning-artifacts/prds/prd-polyomino.dotfiles-2026-08-25/prd.md",
  "_bmad-output/planning-artifacts/architecture/architecture-polyomino.dotfiles-2026-08-25/ARCHITECTURE-SPINE.md",
  "_bmad-output/specs/spec-polyomino.dotfiles/SPEC.md"
]
---

# polyomino.dotfiles - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for polyomino.dotfiles, decomposing the requirements from the PRD, UX Design if it exists, and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: The system must bootstrap Java/Coursier, download the core Scala CLI (`polyomino`), and deploy the full system configuration automatically.
FR2: The system must safely back up existing configuration files to a timestamped archive (`~/.polyomino_backup/`) before symlinking them.
FR3: The system must load enterprise secrets exclusively from an untracked local file (`~/.polyomino.local.zsh`).
FR4: The system must pre-configure tooling, SDKs, and aliases optimized for Java, Kotlin, and Spring Boot development.
FR5: The system must apply a unified cloud-native "Polyomino" theme across Sway, Kitty, Waybar, and Wofi.
FR6: The system must execute read-only health checks on deployed symlinks, binaries, fonts, and PATH configurations.

### NonFunctional Requirements

NFR1: Configuration updates must fail safely without breaking the UI during a workday.
NFR2: The system must maintain timestamped backups of prior states to allow immediate recovery (`polyomino restore`).
NFR3: Background daemons (autotiling, idle management) must have negligible CPU and memory footprints.
NFR4: A bare machine must be fully bootstrapped and ready for Spring Boot development in under 5 minutes.
NFR5: Target OS is strictly Arch Linux and Ubuntu.

### Additional Requirements

- **Starter Template:** The project utilizes an existing Scala 3 / GraalVM codebase (`src/` and `build.sbt`) as its foundation. (IMPORTANT for Epic 1 Story 1).
- Native Monolithic CLI Orchestrator: Built as a single binary dispatching isolated subcommands via a shared mutable `Context`.
- Direct Inline Side-Effects: Modules execute side effects (`os.proc`, `os.write`) inline without `--dry-run` or IoC boundaries.
- Fail-Fast Error Contract: Subcommands must halt immediately on failure, returning `PolyominoError`, without attempting automatic rollbacks.
- Zero-Dependency Native Distribution: CLI distributed exclusively as a self-contained GraalVM native image.

### UX Design Requirements

*(Not applicable)*

### FR Coverage Map

### FR Coverage Map

FR1: Epic 1 - Bootstrapping and Scala CLI setup
FR2: Epic 1 - Timestamped symlink backups
FR3: Epic 1 - Local enterprise secret isolation
FR4: Epic 2 - JVM / Spring Boot tooling setup
FR5: Epic 2 - Cloud-native desktop theming
FR6: Epic 3 - Read-only health checks

## Epic List

### Epic 1: System Bootstrapping & Configuration Engine
Users can take a bare machine and safely automate the complete installation of the core engine and secure dotfiles without losing prior configurations.
**FRs covered:** FR1, FR2, FR3

### Epic 2: Developer Productivity & Unified Theming
Users immediately get a pre-configured JVM Spring Boot environment and a consistent cloud-native 'Polyomino' desktop aesthetic without manual tweaking.
**FRs covered:** FR4, FR5

### Epic 3: System Diagnostics & Maintenance
Users can confidently verify the state of their system configuration and symlinks to prevent or quickly diagnose environment drift.
**FRs covered:** FR6

## Epic 1: System Bootstrapping & Configuration Engine

Users can take a bare machine and safely automate the complete installation of the core engine and secure dotfiles without losing prior configurations.

### Story 1.1: Core CLI Scaffolding & Native Image Build

As a developer,
I want the foundational Scala 3 CLI orchestrator to compile to a GraalVM native image,
So that I have a fast, zero-dependency binary to dispatch commands.

**Acceptance Criteria:**

**Given** the existing Scala 3 project scaffold
**When** the build pipeline is executed
**Then** a GraalVM native image named `polyomino` is successfully compiled
**And** the CLI initializes a mutable `Context` and handles errors using the fail-fast `PolyominoError` contract.

### Story 1.2: System Package Bootstrapper

As a user setting up a bare machine,
I want the CLI to automatically install prerequisite system packages and Java/Coursier,
So that my environment has the required foundation.

**Acceptance Criteria:**

**Given** a fresh Arch Linux or Ubuntu environment
**When** the user executes the bootstrap command
**Then** the CLI identifies the OS and executes inline side-effects to install required system packages via `pacman` or `apt`
**And** the CLI successfully installs Java and Coursier.

### Story 1.3: Symlink Configuration Engine

As a user deploying dotfiles,
I want the CLI to safely back up my existing configs to a timestamped folder before symlinking the new ones,
So that I never lose prior state.

**Acceptance Criteria:**

**Given** existing configuration files in the user's home directory (e.g., `~/.config/sway`)
**When** the configuration deployment routine is run
**Then** the existing files are moved to `~/.polyomino_backup/<timestamp>/`
**And** new symlinks pointing to the repository configurations are created in their place.

### Story 1.4: Enterprise Secrets Guardrail

As an enterprise worker,
I want the system to isolate secrets via a local untracked file (`~/.polyomino.local.zsh`),
So that I never accidentally commit API keys.

**Acceptance Criteria:**

**Given** a user initializing their environment
**When** the system orchestrates the ZSH configuration
**Then** the symlink engine explicitly excludes `~/.polyomino.local.zsh` from version-controlled symlinks
**And** the configuration safely sources this local file if it exists, without failing if it does not.

## Epic 2: Developer Productivity & Unified Theming

Users immediately get a pre-configured JVM Spring Boot environment and a consistent cloud-native 'Polyomino' desktop aesthetic without manual tweaking.

### Story 2.1: JVM & Spring Boot Tooling Setup

As a JVM backend developer,
I want the system to automatically install and configure SDKMAN!, Java, Kotlin, and Spring Boot tooling,
So that I can immediately start coding without manual SDK management.

**Acceptance Criteria:**

**Given** a bootstrapped base system
**When** the user runs the developer tooling setup
**Then** `sdkman` is successfully installed and initialized
**And** the default Java JDK and Kotlin compilers are downloaded and correctly injected into the user's `PATH`.

### Story 2.2: Cloud-Native "Polyomino" Desktop Theme Engine

As a desktop user,
I want the CLI to provide a unified cloud-native "Polyomino" theme across my window manager, status bar, and terminal,
So that my environment is visually consistent and professional.

**Acceptance Criteria:**

**Given** a running Sway/Wayland desktop session
**When** the user executes `polyomino theme <flavor>`
**Then** the color palettes for Sway, Waybar, Wofi, and Kitty are updated using the inline side-effect engine
**And** the UI state reloads safely without crashing or dropping the user's active session.

## Epic 3: System Diagnostics & Maintenance

Users can confidently verify the state of their system configuration and symlinks to prevent or quickly diagnose environment drift.

### Story 3.1: Read-Only System Health Diagnostics

As a desktop user,
I want the CLI to execute read-only health checks on my deployed symlinks, binaries, and fonts,
So that I can quickly identify environment drift or missing dependencies.

**Acceptance Criteria:**

**Given** a deployed environment (fully or partially)
**When** the user runs the `polyomino healthcheck` command
**Then** the system verifies the integrity of symlinks, required `PATH` binaries, and system fonts without mutating the filesystem
**And** the command returns a `PolyominoError` if critical infrastructure is missing, adhering to the fail-fast contract.

## Epic 4: Color Token Engine (Polyomino Theme)
- Define central semantic tokens: Canvas (`#0F1117`), Surface (`#191C24`), Border (`#2B303C`), Axé Gold (`#EBB434`), Maré Teal (`#00D2D3`), Mata Green (`#10AC84`), Terra Red (`#EE5253`), Chalk White (`#F8FAFC`).
- Map tokens into Waybar CSS and Sway window configurations.

### Story 4.1: Define central semantic tokens
Define central semantic tokens: Canvas (`#0F1117`), Surface (`#191C24`), Border (`#2B303C`), Axé Gold (`#EBB434`), Maré Teal (`#00D2D3`), Mata Green (`#10AC84`), Terra Red (`#EE5253`), Chalk White (`#F8FAFC`).

### Story 4.2: Map tokens into Waybar CSS and Sway window configurations
Map tokens into Waybar CSS and Sway window configurations.

## Epic 5: Floating Island Waybar Architecture (Mockup Parity)

### Story 5.1: Refactor Waybar into 3 detached floating segments
Refactor Waybar into 3 detached floating segments with `margin: 8px 12px 0 12px` and `border-radius: 12px`.

### Story 5.2: Implement geometric puzzle/polyomino workspace indicators
Implement geometric puzzle/polyomino workspace indicators (Active: solid gold block `[ ■ ]`; Inactive: wireframe geometric glyphs).

### Story 5.3: Configure center navigation clock capsule
Configure center navigation clock capsule with an astrolabe/compass delimiter.

### Story 5.4: Style right-side hardware capsules and trailing "POLYOMINO" pill
Style right-side hardware capsules (Audio in Green, Wi-Fi in Teal, Battery in Gold) and trailing "POLYOMINO" pill.

## Epic 6: Sway Window Manager Styling

### Story 6.1: Enforce window gaps and corner rounding
Enforce window gaps (`inner 8`, `outer 4`) and corner rounding (`10px–12px`) on floating windows.

### Story 6.2: Set border highlights
Set border highlights (`client.focused = #EBB434`, `client.unfocused = #2B303C`, `client.urgent = #EE5253`).

## Epic 7: Fastfetch Styling & Personal Lore

### Story 7.1: Implement the isometric wireframe Rubik's Cube ASCII graphic
Implement the isometric wireframe Rubik's Cube ASCII graphic in `#EBB434`.

### Story 7.2: Configure custom fastfetch display fields
Configure custom fastfetch display fields: `OS/Theme: Polyomino (Sway dotfiles)` and waypoint `Path: BSB -> LIS`.
