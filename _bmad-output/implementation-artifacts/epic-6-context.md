# Epic 6 Context: Automated Installer & Environment Provisioning Suite

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Deliver machine environment setup (`install`/`deploy`) and granular tool/font installers (`install-fonts`, `install-apps`, `install-browser`, `install-devops`, `install-zsh`, `install-sdkman`, `install-nvim`, `install-nvim-deps`), creating symlinks in `~/.local/bin/`.

## Stories

- Story 6.1: Automated Machine Installer & Symlink Provisioner (`install`/`deploy`)
- Story 6.2: Granular Dependency & Tooling Installers (`install-*`)

## Requirements & Constraints

- **Symlink Deployment**: Create 24 sub-command symlinks (`cumulus-<cmd> -> ~/.local/bin/cumulus`) in `~/.local/bin/` during machine installation.
- **Font & Tool Provisioning**: Download and extract JetBrainsMono Nerd Font to `~/.local/share/fonts/`, running `fc-cache -f`.
- **System Package Manager Integration**: Invoke system package managers (`pacman`, `dnf`, `apt`, `brew`) or shell scripts for developer tools.

## Technical Decisions

- Modules: `cumulus.dotfiles.install.DeployInstaller`, `cumulus.dotfiles.install.ToolInstallers`.
- Use `os-lib` (`os.symlink`, `os.proc`, `os.makeDir`) for installation and symlinking.
