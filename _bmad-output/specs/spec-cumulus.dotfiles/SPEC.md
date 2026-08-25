---
id: SPEC-cumulus.dotfiles
companions:
  - ../../architecture/architecture-cumulus.dotfiles-2026-08-25/ARCHITECTURE-SPINE.md
sources:
  - ../../prds/prd-cumulus.dotfiles-2026-08-25/prd.md
---

> **Canonical contract.** This SPEC and the files in `companions:` are the complete, preservation-validated contract for what to build, test, and validate. Source documents listed in frontmatter are for traceability — consult them only if you need narrative rationale or prose color this contract intentionally omits.

# cumulus.dotfiles Specification

## Why

A vision to realize. The author requires a universally reproducible, enterprise-grade configuration framework for their Sway/Wayland desktop environment. The project solves the pain of manual environment drift and the risk of breaking enterprise work tools, providing a rock-solid, cloud-native (JVM/Spring Boot) development environment that can be spun up reliably on any new machine in under 5 minutes.

## Capabilities

- **CAP-1**
  - **intent:** The system bootstraps the host machine in three stages: installing Java/Coursier, downloading the core Scala CLI, and deploying the desktop configuration.
  - **success:** Running `cumulus install` on a bare Ubuntu/Arch VM successfully sets up all required system packages and the CLI without manual intervention.
- **CAP-2**
  - **intent:** The system links configuration files directly into `$HOME` from the repository, preserving existing files as timestamped backups.
  - **success:** A pre-existing `~/.config/sway` is safely moved to `~/.cumulus_backup/<timestamp>/` and a symlink is created in its place.
- **CAP-3**
  - **intent:** The system isolates enterprise secrets by loading them exclusively from a local, unversioned file (`~/.cumulus.local.zsh`).
  - **success:** Attempting to commit local API keys or loading them globally without the local zsh file is prevented by the configuration pipeline.
- **CAP-4**
  - **intent:** The system applies a unified, cloud-native "Cumulus" aesthetic (e.g., AWS, Azure, GCP themes) across the window manager, status bar, and terminal.
  - **success:** Running `cumulus theme aws` instantly updates Waybar, Sway, and Wofi to the AWS color palette.
- **CAP-5**
  - **intent:** The system provisions out-of-the-box readiness for Java, Kotlin, and Spring Boot backend development.
  - **success:** `sdkman`, Java, and Kotlin compilers are correctly configured in the `PATH` after installation.
- **CAP-6**
  - **intent:** The system executes read-only health checks on deployed symlinks, binaries, and fonts.
  - **success:** `cumulus healthcheck` successfully flags broken symlinks or missing fonts without mutating the filesystem.

## Constraints

- Target environments are strictly limited to Arch Linux and Ubuntu.
- The system must be distributed exclusively as a self-contained GraalVM native image.
- Subcommands must fail-fast without attempting automatic rollback; the system must halt immediately on failure.
- System mutations (side-effects) are executed directly inline without inversion-of-control or dry-run interfaces.

## Non-goals

- Support for macOS, Windows, or non-Wayland display servers (like X11/i3).
- Creation of a GUI configuration wizard (all workflows are strictly CLI-driven).
- Abstractions for package managers other than `pacman` and `apt`.

## Success signal

A completely bare Arch Linux or Ubuntu installation can be converted into a fully themed, secure, and ready-to-code JVM development environment by executing exactly three terminal commands, taking under 5 minutes total.
