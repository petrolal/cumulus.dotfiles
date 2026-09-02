---
title: polyomino.dotfiles PRD
status: final
created: "2026-08-25"
updated: "2026-08-25"
---

# Product Requirements Document: polyomino.dotfiles

## 1. Vision & Purpose
`polyomino.dotfiles` is a universally reproducible, enterprise-stable configuration framework for Sway/Wayland desktop environments. Its primary goal is to provide a rock-solid, default operational environment that can be deployed across any personal or enterprise workstation. It is heavily optimized for cloud-native JVM backend development (Java, Kotlin, Spring Boot) and unifies the aesthetic under a custom "Polyomino" theme.

## 2. Target Audience & Environment
- **Primary User**: The author, operating in both personal and strict enterprise environments.
- **Target OS**: Strictly Arch Linux and Ubuntu. The installer and bootstrap mechanisms must natively handle package management and dependencies for these two distributions.

## 3. Core Features (Capabilities)
### 3.1. Automated Bootstrapping & Symlink Management
- **3-Stage Installation**: The system must bootstrap Java/Coursier, download the core Scala CLI (`polyomino`), and deploy the full system configuration automatically.
- **Safe Symlinking**: Configuration files are symlinked rather than copied. If a target file already exists, it must be safely backed up to a timestamped archive (`~/.polyomino_backup/`) before the symlink is created.

### 3.2. Enterprise Secret Isolation
- **Local Credentials**: The system must enforce the isolation of enterprise secrets, API keys, and environment variables. These are loaded exclusively from an untracked local file (`~/.polyomino.local.zsh`), ensuring no credential leakage into version control.

### 3.3. JVM & Cloud-Native Optimization
- **Development Tooling**: The environment must come pre-configured with the necessary tooling, SDKs, and aliases optimized for Java, Kotlin, and Spring Boot backend development.
- **Polyomino Theming**: A customized, cohesive cloud-native aesthetic (supporting sub-themes like AWS, Azure, GCP) applied consistently across the window manager (Sway), terminal (Kitty), status bar (Waybar), and application launcher (Wofi).

### 3.4. System Health & Maintenance
- **Health Checks**: A built-in diagnostic command to verify system health, validating that all symlinks, binaries, fonts, and PATH configurations are correctly deployed.

## 4. Non-Functional Requirements (NFRs)
- **Enterprise Stability (Safe Updates)**: Configuration updates must never break the UI during a workday. The installation and update processes must fail safely without leaving the system in a broken state.
- **Automated Rollbacks**: The system must maintain timestamped backups of prior states (`polyomino backup` / `polyomino restore`) to allow immediate recovery in case of a bad update.
- **Performance**: The window manager and terminal must remain highly responsive. Background daemons (e.g., autotiling, idle management) must have negligible CPU and memory footprints.

## 5. Success Metrics
- **Time to Productivity**: A bare Arch or Ubuntu machine can be fully bootstrapped and ready for enterprise Spring Boot development in under 5 minutes.
- **Workday Reliability**: Zero interruptions to enterprise work caused by local configuration updates or environment drift.
