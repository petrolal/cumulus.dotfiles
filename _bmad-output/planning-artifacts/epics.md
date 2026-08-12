---
stepsCompleted: [1, 2, 3, 4]
inputDocuments:
  - _bmad-output/planning-artifacts/architecture/architecture-cumulus.dotfiles-2026-08-12/ARCHITECTURE-SPINE.md
  - Cargo.toml
  - src/lib.rs
---

# cumulus.dotfiles Scala Migration - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for cumulus.dotfiles Scala migration, decomposing the requirements from the Architecture Spine and existing Rust codebase into implementable user stories.

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

### NonFunctional Requirements

- **NFR1: GraalVM AOT Native Compilation**: Compile the entire Scala codebase into a single standalone native Linux ELF executable (`cumulus`) using GraalVM `native-image` and `sbt-native-image` 0.5.0 with zero JVM runtime dependencies on target systems.
- **NFR2: Low Execution Latency**: Maintain CLI startup and execution latency within 15–50 ms across subcommands.
- **NFR3: Memory Efficiency**: Maintain baseline execution RSS memory footprint under 60 MB.
- **NFR4: Zero Reflection Serialization**: All JSON config parsing and generation must use compile-time derived `uPickle` macros to prevent GraalVM reflection configuration overhead.

### Additional Requirements

- **AD-1 (Single Multi-Call Binary)**: Build 1 single executable `cumulus` and set up symlinks (`cumulus-<cmd> -> cumulus`) during installation to prevent multi-target GraalVM build time multiplication.
- **AD-2 (Non-Reflective I/O)**: Use `os-lib` (`0.11.9-M8`) for all file/process operations and `uPickle` (`4.4.3`) for JSON.
- **AD-3 (CLI Dispatch Routing)**: Implement `cumulus.Main` with `mainargs` (`0.7.0`) for flag parsing and sub-command routing.
- **AD-4 (Streamed Process Execution)**: Stream stdout/stderr for subprocess invocations (`swaymsg`, `wofi`, `pactl`) to avoid memory buffering.
- **Stack Definition**: Scala 3.5.2, JDK 21 GraalVM Community Edition, sbt 1.10.2.

### UX Design Requirements

*(N/A - Desktop CLI and Wofi GUI pickers follow existing Sway/Wofi themes)*

### FR Coverage Map

- **FR1 (Umbrella CLI & Symlink Dispatcher)**: Epic 1 (Story 1.1, Story 1.2)
- **FR2 (Desktop Theme Engine)**: Epic 3 (Story 3.1)
- **FR3 (Runtime Refresh Engine & Color Sync)**: Epic 3 (Story 3.2)
- **FR4 (Sway Autotiling Daemon)**: Epic 4 (Story 4.1)
- **FR5 (System Desktop Helpers)**: Epic 2 (Story 2.4)
- **FR6 (System Validation & Health Check)**: Epic 2 (Story 2.2)
- **FR7 (Maintenance & Backup Suite)**: Epic 5 (Story 5.1, Story 5.2)
- **FR8 (Spec-Driven Development Context)**: Epic 2 (Story 2.3)
- **FR9 (Graphical Wofi Pickers)**: Epic 3 (Story 3.3)
- **FR10 (Automated Installer Suite)**: Epic 6 (Story 6.1, Story 6.2)

---

## Epic List

### Epic 1: Scala Build Pipeline & Multi-Call CLI Dispatcher

Build the core Scala 3 project structure, `sbt-native-image` build pipeline, and `cumulus.Main` multi-call binary entrypoint capable of routing symlinked `cumulus-<cmd>` or umbrella `cumulus <cmd>` CLI invocations.
**FRs covered:** FR1

#### Story 1.1: sbt Project & GraalVM Native Image Build Scaffold

As a maintainer,
I want an `sbt` project configured with `sbt-native-image`, `os-lib`, `uPickle`, and `mainargs`,
So that I can compile the Scala 3 codebase into a single standalone native binary (`cumulus`) without JVM runtime dependencies.

**Acceptance Criteria:**

**Given** an `sbt` 1.10 build file configured with Scala 3.5.2 and `sbt-native-image` 0.5.0
**When** executing `sbt nativeImage`
**Then** a compiled Linux ELF executable named `cumulus` is generated in `target/native-image/`
**And** the binary executes natively on Linux systems without requiring Java/JVM.

#### Story 1.2: Multi-Call Binary Entrypoint & Symlink Dispatcher

As a user,
I want `cumulus` to inspect `argv(0)` and `argv(1)` to strip `cumulus-` prefixes,
So that executing symlinks like `cumulus-theme` or umbrella commands like `cumulus theme` executes the correct Scala submodule.

**Acceptance Criteria:**

**Given** the compiled native binary `cumulus` and a symlink `cumulus-autotiling -> cumulus`
**When** executing `cumulus-autotiling` or `cumulus autotiling`
**Then** `cumulus.Main` correctly extracts the subcommand name `autotiling`
**And** passes trailing arguments to the appropriate Scala module handler, returning exit code 0 on success or non-zero on failure.

---

## Epic 2: Core System Context, Validation & Desktop Helpers

Implement context discovery (`Context`), read-only system health validation (`validate`), AI development context generation (`sdd`), screen locking (`lock`), auto-idle management (`idle`), and screenshot capture (`screenshot`).
**FRs covered:** FR5, FR6, FR8

#### Story 2.1: System Context Discovery & Environment Resolution

As a desktop module developer,
I want a `Context` discovery object that locates home directory, XDG paths (`~/.config`, `~/.local/share`), active theme state, and Sway IPC socket paths,
So that all subcommands have consistent environment facts.

**Acceptance Criteria:**

**Given** a Linux Sway desktop session
**When** `Context.discover()` is called from any Scala submodule
**Then** it returns an immutable `Context` case class with resolved `os.Path` handles for `~/.config`, `~/.local/share/cumulus`, active theme metadata, and `SWAYSOCK` Unix domain socket path.

#### Story 2.2: System Validation & Read-Only Health Check (`validate`)

As a user,
I want `cumulus validate` to check required binaries, config files, environment variables, and font installations,
So that I can verify my desktop installation health.

**Acceptance Criteria:**

**Given** a deployed `cumulus.dotfiles` setup
**When** executing `cumulus validate`
**Then** read-only checks run for required CLI utilities (`sway`, `waybar`, `kitty`, `wofi`, `swaylock`, `grim`, `slurp`), configuration paths, and environment variables
**And** prints formatted pass/fail status lines, returning exit code 0 if all core components exist or non-zero if required components are missing.

#### Story 2.3: Spec-Driven Development Context Generator (`sdd`)

As a developer,
I want `cumulus sdd` to generate token-efficient AI context files and project specs,
So that AI assistants can analyze system state cleanly.

**Acceptance Criteria:**

**Given** a target directory or spec identifier
**When** executing `cumulus sdd [target]`
**Then** system files and configuration contexts are collected using `os-lib`
**And** formatted into token-efficient markdown context streamed to stdout or target file.

#### Story 2.4: System Lock Screen, Auto-Idle & Screenshot Helpers (`lock`, `idle`, `screenshot`)

As a desktop user,
I want `cumulus lock`, `cumulus idle`, and `cumulus screenshot` helpers,
So that I can lock the screen styled with active theme colors, run swayidle, and capture screenshots.

**Acceptance Criteria:**

**Given** Sway window manager is active
**When** executing `cumulus lock`
**Then** `swaylock` is launched styled with active theme colors using `os.proc`
**And** when executing `cumulus screenshot region`, `grim` and `slurp` are invoked to capture the selected screen region to file and clipboard.

---

## Epic 3: Live Theme Engine, Color Sync & Wofi Pickers

Implement live desktop theme application across Sway, Waybar, Kitty, Wofi, GTK, Neovim, and OpenRGB (`theme`), runtime app refresh (`runtime-refresh`, `os-colorscheme`, `rgb-theme`), and interactive Wofi GUI pickers (`theme-picker`, `whichkey`).
**FRs covered:** FR2, FR3, FR9

#### Story 3.1: Live Desktop Theme Application Engine (`theme`)

As a desktop user,
I want `cumulus theme <flavor> [mode]`,
So that I can dynamically switch colors and wallpapers live across Sway, Waybar, Kitty, Wofi, Neovim, GTK, and OpenRGB.

**Acceptance Criteria:**

**Given** a valid theme flavor name (e.g. `catppuccin-mocha`)
**When** executing `cumulus theme catppuccin-mocha dark`
**Then** theme configuration files are updated in `~/.config/` via `os-lib`
**And** live reload signals are sent to Sway (`swaymsg reload`), Kitty (`kill -USR1`), Waybar, and GTK settings.

#### Story 3.2: Runtime App Refresh & Color Scheme Synchronization (`runtime-refresh`, `os-colorscheme`, `rgb-theme`)

As a desktop user,
I want runtime refresh commands to sync GNOME/GTK dark mode preference and OpenRGB lighting colors,
So that system appearance remains unified.

**Acceptance Criteria:**

**Given** an active desktop theme
**When** executing `cumulus runtime-refresh`, `cumulus os-colorscheme`, or `cumulus rgb-theme`
**Then** running applications refresh their color schemes without restarting
**And** GNOME `gsettings` `color-scheme` and OpenRGB hardware lighting profiles update to match the active theme.

#### Story 3.3: Interactive Wofi GUI Theme & Cheatsheet Pickers (`theme-picker`, `whichkey`)

As a GUI user,
I want `cumulus theme-picker` and `cumulus whichkey` to pop up Wofi dialogs,
So that I can visually choose themes or view Sway keybindings.

**Acceptance Criteria:**

**Given** a keybinding configured in Sway for `cumulus-theme-picker` or `cumulus-whichkey`
**When** triggered by keyboard shortcut
**Then** a Wofi launcher opens listing available themes or active keybindings
**And** selecting a theme entry immediately triggers `cumulus theme <selected>`.

---

## Epic 4: Sway Fibonacci Autotiling Daemon

Implement the Sway IPC event listener daemon that dynamically arranges window layout splits into a Fibonacci spiral as windows are created or focused (`autotiling`).
**FRs covered:** FR4

#### Story 4.1: Sway IPC Unix Domain Socket Event Listener (`autotiling`)

As a Sway desktop user,
I want `cumulus autotiling` to connect to the Sway IPC socket and monitor window creation/focus events,
So that window split orientations update automatically in a Fibonacci spiral layout.

**Acceptance Criteria:**

**Given** Sway running with `SWAYSOCK` set
**When** `cumulus autotiling` is launched as a background daemon
**Then** it connects to the Unix domain socket and subscribes to Sway `window` events
**And** automatically issues `swaymsg split v` or `swaymsg split h` commands based on the focused window's width vs height ratio.

---

## Epic 5: Maintenance & Backup Suite

Implement system maintenance commands to create timestamped tarball backups of dotfiles (`backup`), restore configuration snapshots (`restore`), and re-pull/install dotfiles updates (`update`).
**FRs covered:** FR7

#### Story 5.1: Configuration Snapshot Backup & Restore (`backup`, `restore`)

As a user,
I want `cumulus backup` and `cumulus restore`,
So that I can create timestamped tarball archives of dotfiles configs and restore them if needed.

**Acceptance Criteria:**

**Given** managed configuration files in `~/.config/`
**When** executing `cumulus backup`
**Then** a compressed `.tar.gz` archive containing dotfiles state is saved to `~/.local/share/cumulus/backups/`
**And** executing `cumulus restore <archive>` safely extracts and restores the snapshot.

#### Story 5.2: Dotfiles Git Update & Installer Trigger (`update`)

As a user,
I want `cumulus update`,
So that I can pull the latest dotfiles changes from git and re-run installer scripts automatically.

**Acceptance Criteria:**

**Given** the dotfiles repository in `~/cumulus.dotfiles`
**When** executing `cumulus update`
**Then** `git pull --rebase` is executed via `os-lib`
**And** `cumulus install` is triggered to redeploy updated configs and symlinks.

---

## Epic 6: Automated Installer & Environment Provisioning Suite

Implement automated machine setup (`install`/`deploy`), installing symlinks into `~/.local/bin`, along with granular installer submodules for fonts, desktop apps, web browser, DevOps tools, Zsh, SDKMAN!, and Neovim dependencies (`install-*`).
**FRs covered:** FR10

#### Story 6.1: Automated Machine Installer & Symlink Provisioner (`install`/`deploy`)

As a new machine setup user,
I want `cumulus install`,
So that dotfiles configurations are deployed and `cumulus-<command>` symlinks are created in `~/.local/bin`.

**Acceptance Criteria:**

**Given** a clean Linux system
**When** executing `cumulus install`
**Then** config files are symlinked to `~/.config/`
**And** 24 sub-command symlinks (`cumulus-autotiling`, `cumulus-theme`, etc.) pointing to `~/.local/bin/cumulus` are created in `~/.local/bin/`.

#### Story 6.2: Granular Dependency & Tooling Installers (`install-*`)

As a developer,
I want granular `cumulus install-fonts`, `install-apps`, `install-browser`, `install-devops`, `install-zsh`, `install-sdkman`, `install-nvim`, and `install-nvim-deps` commands,
So that I can selectively install system packages and developer tools.

**Acceptance Criteria:**

**Given** a specific installer subcommand (e.g., `cumulus install-fonts`)
**When** executed via CLI
**Then** JetBrainsMono Nerd Font archives are downloaded, extracted to `~/.local/share/fonts/`, and registered with `fc-cache -f`.
