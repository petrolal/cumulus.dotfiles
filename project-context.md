# project-context.md — cumulus.dotfiles AI Context & System Architecture

## Project Overview & Purpose

`cumulus.dotfiles` is a lightweight, high-performance desktop environment tooling suite designed for Sway/Wayland Linux desktop environments. It manages dynamic window autotiling, desktop theme switching across application surfaces, hardware RGB synchronization, system health validation, config snapshot maintenance, and automated machine provisioning.

The suite follows a **Multi-Call Binary Architecture**: all sub-commands and helper scripts compile into a single executable umbrella (`cumulus`). Sub-command invocations like `cumulus-theme` or `cumulus-autotiling` are handled via filesystem symlinks pointing to `cumulus`. The main binary inspects `argv[0]` or `argv[1]` to route execution to the target submodule.

---

## Technical Stack

### Current Implementation (Rust Baseline)
- **Language & Edition**: Rust 2021 (Rust 1.74+)
- **Build Profile**: Binary optimization for size (`opt-level = "z"`, `lto = true`, `strip = true`, `codegen-units = 1`)
- **Dependencies**: `serde` (1.0.229), `serde_json` (1.0.151), POSIX libc/standard library
- **Target OS / Environment**: Arch Linux / Fedora Linux on Wayland with Sway window manager

### Target Migration Stack (Scala 3 + GraalVM AOT)
- **Language**: Scala 3.5.2
- **JDK Base**: JDK 21 GraalVM Community Edition
- **Build Tool**: `sbt` 1.10.2 with `sbt-native-image` 0.5.0 plugin
- **System I/O & Process Spawning**: `os-lib` (`com.lihaoyi %% os-lib % "0.11.9-M8"`)
- **JSON Serialization**: `uPickle` (`com.lihaoyi %% upickle % "4.4.3"`) using static compile-time macros (zero JVM reflection)
- **CLI Parsing**: `mainargs` (`com.lihaoyi %% mainargs % "0.7.0"`)

---

## Architectural Invariants & Patterns

1. **Single Multi-Call Native Executable**:
   - All modules (`autotiling`, `theme`, `refresh`, `sysutils`, `maintenance`, `install`, `pickers`, `sdd`, `validate`) compile into a single binary (`cumulus`).
   - Command aliases (`cumulus-<subcommand>`) are symlinks pointing to `cumulus` installed in `~/.local/bin`.

2. **Non-Reflective System I/O**:
   - Process execution and file manipulation use `os-lib` (`os.proc`, `os.read`, `os.write`).
   - JSON parsing uses `uPickle` derive macros to remain 100% GraalVM `native-image` compatible without `reflect-config.json`.

3. **Streamed Process Execution**:
   - Heavy sub-process output (`swaymsg`, `wofi`, `pactl`) streams directly without intermediate heap buffering, maintaining low memory usage.

4. **Performance Targets**:
   - **Startup Latency**: 15 ms – 50 ms execution time.
   - **Memory RSS**: Under 60 MB peak RAM.

---

## Desktop Surface Integrations

`cumulus.dotfiles` coordinates state and configuration files across the following desktop components:

- **Sway Window Manager**: IPC socket communication (`SWAYSOCK`) for layout autotiling (`swaymsg split v/h`) and window reloads.
- **Waybar**: Desktop status bar reloads and signal triggers (`pkill -SIGUSR1 waybar`).
- **Kitty Terminal**: Live theme color palette updates via IPC signaling (`kill -USR1`).
- **Wofi Launcher**: Graphical UI menus for theme selection (`theme-picker`) and keybindings cheatsheet (`whichkey`).
- **Neovim / GTK**: Color scheme synchronization (`gsettings set org.gnome.desktop.interface color-scheme`).
- **OpenRGB**: Hardware RGB lighting profile synchronization.
- **Swaylock & Swayidle**: Lock screen styling and auto-lock/DPMS power management daemons.

---

## Project Structure Map

```text
cumulus.dotfiles/
├── Cargo.toml                 # Rust library & binary package manifest
├── README.md                  # System usage & command documentation
├── bootstrap.sh               # Quick installer bootstrap script
├── src/                       # Rust source modules
│   ├── main.rs                # Multi-call binary entrypoint
│   ├── lib.rs                 # Core dispatch router & command registration
│   ├── autotiling.rs          # Sway IPC Fibonacci autotiling daemon
│   ├── collate.rs             # File collection helpers
│   ├── context.rs             # Environment & XDG path discovery
│   ├── error.rs               # Result/Error domain definitions
│   ├── install/               # Automated installer submodules (fonts, apps, devops, zsh, nvim)
│   ├── maintenance.rs         # Backup snapshot, restore & update commands
│   ├── pickers.rs             # Wofi GUI launchers (theme-picker, whichkey)
│   ├── refresh.rs             # Runtime app refresh, GTK color sync, OpenRGB sync
│   ├── sdd.rs                 # Spec-driven development AI context generator
│   ├── sysutils.rs            # Lock screen, idle daemon, screenshot helpers
│   ├── theme/                 # Desktop theme engine & wallpaper management
│   ├── util.rs                # Shared process & file utilities
│   └── validate.rs            # Read-only health check validator
└── _bmad-output/              # BMad architecture & epic planning artifacts
    └── planning-artifacts/
        ├── architecture/      # Architecture Spine (ARCHITECTURE-SPINE.md)
        └── epics.md           # Epic breakdown & user story specifications
```

---

## Subcommands & Use Cases

| Subcommand | Alias Symlink | Primary Purpose / Use Case |
| :--- | :--- | :--- |
| `theme` | `cumulus-theme` | Apply desktop theme flavor + wallpaper mode live across Sway/Kitty/Waybar/GTK |
| `runtime-refresh` | `cumulus-runtime-refresh` | Trigger live reload signals across running desktop applications |
| `os-colorscheme` | `cumulus-os-colorscheme` | Sync GNOME/GTK dark/light color scheme setting |
| `rgb-theme` | `cumulus-rgb-theme` | Sync OpenRGB hardware lighting with active theme accent color |
| `autotiling` | `cumulus-autotiling` | Background daemon listening to Sway IPC to apply Fibonacci spiral window splits |
| `lock` | `cumulus-lock` | Lock screen via `swaylock` styled with active theme colors |
| `idle` | `cumulus-idle` | Launch `swayidle` daemon for auto-lock, DPMS screen off, and suspend |
| `screenshot` | `cumulus-screenshot` | Capture screen selection (full/region/window) to file and clipboard |
| `validate` | `cumulus-validate` | Read-only health check validating configs, tools, fonts, and env variables |
| `backup` | `cumulus-backup` | Create timestamped `.tar.gz` archive of dotfiles configurations |
| `restore` | `cumulus-restore` | Restore a snapshot created by `cumulus backup` |
| `update` | `cumulus-update` | Git pull dotfiles repository and re-run installer deployment |
| `sdd` | `cumulus-sdd` | Generate token-efficient AI context and specs for development workflows |
| `theme-picker` | `cumulus-theme-picker` | Launch Wofi GUI menu to select and apply desktop themes |
| `whichkey` | `cumulus-whichkey` | Launch Wofi GUI cheatsheet displaying live Sway keybindings |
| `install` | `cumulus-install` | Deploy dotfiles configurations and create `cumulus-*` symlinks in `~/.local/bin` |
| `install-fonts` | `cumulus-install-fonts` | Download and install JetBrainsMono Nerd Font |
| `install-apps` | `cumulus-install-apps` | Install core desktop GUI & CLI applications |
| `install-browser` | `cumulus-install-browser` | Install web browser (Brave / Chromium) |
| `install-devops` | `cumulus-install-devops` | Install DevOps tooling (Docker, Terraform, Kubectl, Helm) |
| `install-zsh` | `cumulus-install-zsh` | Install Zsh, Oh My ZSH, and plugin suite |
| `install-sdkman` | `cumulus-install-sdkman` | Install SDKMAN! and JVM development tooling |
| `install-nvim` | `cumulus-install-nvim` | Deploy Neovim configuration files |
| `install-nvim-deps` | `cumulus-install-nvim-deps` | Install Neovim LSP servers, formatters, and treesitter dependencies |
