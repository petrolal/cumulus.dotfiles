# Epic 7 Context: Deep Installer Engine, Manifest Tracking & Tooling Provisioners

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Deliver `.dotfiles_manifest` tracking, pre-dotfiles config backup preservation (`~/.config/*.bak`), and deep package manager integration (`pacman`, `dnf`, `apt`, `brew`) for core applications, browser, DevOps tools, Zsh, SDKMAN!, and Neovim dependencies.

## Stories

- Story 7.1: Dotfiles Manifest Tracking & Deployment Engine
- Story 7.2: Comprehensive Tooling & Package Manager Provisioners

## Requirements & Constraints

- **Manifest Tracking**: Generate a JSON manifest file (`~/.local/share/cumulus/manifest.json`) tracking deployed symlinks and backup locations.
- **Pre-Config Preservation**: Safely copy existing pre-dotfiles config directories/files to `.bak` before symlinking to prevent user data loss.
- **Package Manager Integration**: Auto-detect Linux distribution package manager (`pacman`, `dnf`, `apt`, `brew`) and execute non-interactive installation commands via `os-lib`.

## Technical Decisions

- Modules: `cumulus.dotfiles.install.DeployInstaller`, `cumulus.dotfiles.install.ToolInstallers`.
- Serialization: Use `uPickle` static `ReadWriter` macros for reading/writing `manifest.json`.
