---
title: 'Story 7.1: Dotfiles Manifest Tracking & Deployment Engine'
type: 'feature'
created: '2026-08-12'
status: 'done'
baseline_commit: '925da25'
review_loop_iteration: 0
context:
  - _bmad-output/implementation-artifacts/epic-7-context.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Machine deployment needs to track deployed symlinks in a `.dotfiles_manifest` and preserve pre-existing user configurations as backups so installation never loses user data.

**Approach:** Expand `DeployInstaller` in Scala 3 using `uPickle` for `Manifest` JSON serialization, backing up existing configs to `.bak` before symlinking, and writing `manifest.json`.

## Boundaries & Constraints

**Always:** Use `os-lib` (`os.copy`, `os.symlink`, `os.write`) for manifest and backup operations; write `manifest.json` under `~/.local/share/cumulus/`.

**Ask First:** Overwriting existing `.bak` directories without timestamping.

**Never:** Delete pre-existing user configuration files without creating a backup copy first.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Existing Config | `~/.config/sway` exists as dir | Copies `~/.config/sway` -> `~/.config/sway.bak` before symlinking | Reports copy errors |
| Manifest Creation | `cumulus install` | Writes `~/.local/share/cumulus/manifest.json` with deployed symlinks | Reports JSON write errors |

</frozen-after-approval>

## Code Map

- `src/main/scala/cumulus/dotfiles/install/DeployInstaller.scala` -- Deploys config symlinks, backs up pre-existing configs, writes manifest JSON.
- `src/main/scala/cumulus/dotfiles/install/Manifest.scala` -- Manifest data structure with uPickle ReadWriter derivation.

## Tasks & Acceptance

**Execution:**
- [x] `src/main/scala/cumulus/dotfiles/install/Manifest.scala` -- Create `Manifest` case class with `uPickle` serialization -- Manifest data model.
- [x] `src/main/scala/cumulus/dotfiles/install/DeployInstaller.scala` -- Implement pre-config backup & manifest JSON generation -- Manifest deployment logic.

**Acceptance Criteria:**
- Given pre-existing configuration files in `~/.config/`, when executing `cumulus install`, then backups are created at `~/.config/*.bak` and `manifest.json` is generated.

## Verification

**Commands:**
- `sbt compile` -- expected: SUCCESS_CRITERIA

## Suggested Review Order

**Dotfiles Manifest Tracking & Deployment Engine**

- Manifest serializable data model
  [`Manifest.scala:1`](../../src/main/scala/cumulus/dotfiles/install/Manifest.scala#L1)

- Pre-config `.bak` backup and `manifest.json` generation
  [`DeployInstaller.scala:1`](../../src/main/scala/cumulus/dotfiles/install/DeployInstaller.scala#L1)

