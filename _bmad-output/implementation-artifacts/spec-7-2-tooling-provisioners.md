---
title: 'Story 7.2: Comprehensive Tooling & Package Manager Provisioners'
type: 'feature'
created: '2026-08-12'
status: 'done'
baseline_commit: '282c9ff'
review_loop_iteration: 0
context:
  - _bmad-output/implementation-artifacts/epic-7-context.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Individual tool installers (`install-apps`, `install-browser`, `install-devops`, `install-zsh`, `install-sdkman`, `install-nvim-deps`) need to detect the host package manager (`pacman`, `dnf`, `apt`, `brew`) and execute non-interactive installation steps.

**Approach:** Expand `ToolInstallers` in Scala 3 with package manager detection helper `PackageManager.detect()` and package installation procedures.

## Boundaries & Constraints

**Always:** Check for package manager binaries using `os.proc("which", pm)` and pass non-interactive flags (`--noconfirm`, `-y`).

**Ask First:** Running `sudo` package installation commands without user confirmation.

**Never:** Fail silently on failed package manager downloads.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Arch System | `pacman` available | Executes `sudo pacman -S --noconfirm <pkgs>` | Reports package manager error |
| Fedora System | `dnf` available | Executes `sudo dnf install -y <pkgs>` | Reports package manager error |

</frozen-after-approval>

## Code Map

- `src/main/scala/cumulus/dotfiles/install/ToolInstallers.scala` -- Package manager detection and tool installer procedures.

## Tasks & Acceptance

**Execution:**
- [x] `src/main/scala/cumulus/dotfiles/install/ToolInstallers.scala` -- Implement package manager detection & package installation procedures -- Tool installer procedures.

**Acceptance Criteria:**
- Given an Arch or Fedora system, when running `cumulus install-devops`, then package manager detection identifies `pacman` or `dnf` and executes installation commands.

## Verification

**Commands:**
- `sbt compile` -- expected: SUCCESS_CRITERIA

## Suggested Review Order

**Comprehensive Tooling & Package Manager Provisioners**

- Package manager auto-detection (`pacman`, `dnf`, `apt`, `brew`) and tool installers
  [`ToolInstallers.scala:1`](../../src/main/scala/cumulus/dotfiles/install/ToolInstallers.scala#L1)

