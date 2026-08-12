---
title: 'Epic 6: Automated Installer & Environment Provisioning Suite'
type: 'feature'
created: '2026-08-12'
status: 'done'
baseline_commit: 'b3f20bd'
review_loop_iteration: 0
context:
  - _bmad-output/implementation-artifacts/epic-6-context.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Machine deployment setup (`install`), binary symlink creation, and granular tool installers (`install-*`) are missing in the Scala codebase.

**Approach:** Implement `DeployInstaller` and `ToolInstallers` using `os-lib` to create configuration symlinks in `~/.config/`, 24 command symlinks in `~/.local/bin/`, and provision developer tools/fonts.

## Boundaries & Constraints

**Always:** Ensure `~/.local/bin/` exists and is populated with `cumulus-<cmd> -> cumulus` symlinks.

**Ask First:** Overwriting non-symlink config files without prompt.

**Never:** Delete existing user environment files outside dotfiles scope.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Full Machine Install | `cumulus install` | Symlinks configs to `~/.config/` & creates 24 `cumulus-*` symlinks | Reports symlink creation errors |
| Install Fonts | `cumulus install-fonts` | Downloads & extracts JetBrainsMono to `~/.local/share/fonts/` | Runs `fc-cache -f` |
| Install Dev Tools | `cumulus install-devops` | Provisions Docker, Terraform, Kubectl helpers | Reports missing package manager |

</frozen-after-approval>

## Code Map

- `src/main/scala/cumulus/dotfiles/install/DeployInstaller.scala` -- Full machine deployment installer & symlink provisioner.
- `src/main/scala/cumulus/dotfiles/install/ToolInstallers.scala` -- Granular tool/font installers (`install-fonts`, `install-apps`, etc.).
- `src/main/scala/cumulus/Main.scala` -- Connects `install` and `install-*` subcommands.

## Tasks & Acceptance

**Execution:**
- [x] `src/main/scala/cumulus/dotfiles/install/DeployInstaller.scala` -- Implement `DeployInstaller.run(ctx, args)` -- Full deployment installer.
- [x] `src/main/scala/cumulus/dotfiles/install/ToolInstallers.scala` -- Implement `ToolInstallers.runTool(name, ctx, args)` -- Granular tool installers.
- [x] `src/main/scala/cumulus/Main.scala` -- Wire `install` and `install-*` subcommands to installer handlers -- Dispatch integration.

**Acceptance Criteria:**
- Given a clean environment, when executing `cumulus install`, then configuration symlinks and 24 `cumulus-*` binary symlinks in `~/.local/bin/` are created.
- Given `cumulus install-fonts`, when executed, JetBrainsMono Nerd Font is downloaded and installed.

## Verification

**Commands:**
- `sbt compile` -- expected: SUCCESS_CRITERIA

## Suggested Review Order

**Automated Installer & Environment Provisioning Suite**

- Machine deployment installer and subcommand symlink creation
  [`DeployInstaller.scala:1`](../../src/main/scala/cumulus/dotfiles/install/DeployInstaller.scala#L1)

- Granular font and tool installers
  [`ToolInstallers.scala:1`](../../src/main/scala/cumulus/dotfiles/install/ToolInstallers.scala#L1)

- Main CLI dispatcher wiring for installer subcommands
  [`Main.scala:55`](../../src/main/scala/cumulus/Main.scala#L55)

