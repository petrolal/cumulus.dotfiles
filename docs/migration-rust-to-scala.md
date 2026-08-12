# Rust to Scala Migration Specification — cumulus.dotfiles

## 1. Executive Summary & Migration Status

- **Status**: **Phase 1 Complete (Architecture & Requirements Breakdown Finalized)**
- **Current Baseline**: Rust 2021 codebase (`src/`, `Cargo.toml`) supplying 24 multi-call CLI subcommands for Sway/Wayland Linux desktop automation.
- **Target Stack**: **Scala 3.5.2** compiled via **GraalVM `native-image`** (`sbt-native-image` 0.5.0, JDK 21 base) into a single standalone native Linux ELF binary (`cumulus`).
- **Primary Driver**: Maintainer ergonomics and JVM ecosystem familiarity (Java/Kotlin/Scala).
- **Accepted Trade-offs**: Startup latency tolerance of 15ms–50ms (acceptable for Sway hooks) and 1–5 minute GraalVM compilation times during release builds.

---

## 2. Pinned Stack & Architectural Rules

### Technology Stack Pins

| Component | Technology | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **Language** | Scala | `3.5.2` | Primary development language |
| **JVM Base** | GraalVM Community Edition | `21.0.2` | AOT compilation engine |
| **Build Tool** | `sbt` | `1.10.2` | Build and dependency management |
| **AOT Plugin** | `sbt-native-image` | `0.5.0` | sbt task for GraalVM `native-image` generation |
| **Process & File I/O** | `os-lib` | `0.11.9-M8` | POSIX subprocess spawning and filesystem operations |
| **JSON Parser** | `uPickle` | `4.4.3` | Compile-time static derive macro serialization (zero reflection) |
| **CLI Parser** | `mainargs` | `0.7.0` | Command line parameter parsing |

### Architectural Invariants & Rules

- **AD-1 — Single Multi-Call Native Binary Target `[ADOPTED]`**
  - All 24 subcommand entrypoints must compile into a single executable `cumulus`. Subcommand aliases (`cumulus-autotiling`, `cumulus-theme`, etc.) are created as filesystem symlinks pointing to `cumulus` in `~/.local/bin`.
  - *Prevents:* Multiplying GraalVM build times by 24x (~40+ minutes of build time) and duplicating Substrate VM memory footprints.

- **AD-2 — Non-Reflective JSON & System I/O Abstractions `[ADOPTED]`**
  - File/process operations MUST use `os-lib`. JSON serialization MUST use `uPickle` static `ReadWriter` macros.
  - *Prevents:* Reflection runtime crashes under GraalVM Native Image and eliminates complex `reflect-config.json` setup.

- **AD-3 — Pure Command-Line Argument Parsing Strategy `[ADOPTED]`**
  - `cumulus.Main` inspects `argv(0)` to detect `cumulus-<cmd>` symlinks or `argv(1)` under umbrella `cumulus <cmd>` calls, stripping prefixes and delegating cleanly to submodules.
  - *Prevents:* Signature mismatch between symlinks and umbrella invocations.

- **AD-4 — Direct Process Stream Handling & Zero Heap Bloat `[ADOPTED]`**
  - Subprocess calls (`swaymsg`, `wofi`, `swaylock`, `pactl`) must stream stdout/stderr using `os.proc(...).call()` or `os.proc(...).spawn()`.
  - *Prevents:* Unnecessary JVM heap buffer allocations during high-frequency Sway window focus events.

---

## 3. Module & Use Case Migration Mapping

The table below maps every legacy Rust module in `src/` to its corresponding target Scala package, primary use case, and assigned Epic/Story:

| Legacy Rust Module | Target Scala Module | Primary Use Case | Epic / Story Reference |
| :--- | :--- | :--- | :--- |
| `src/main.rs` & `src/lib.rs` | `cumulus.Main` | Umbrella `argv(0)` CLI dispatcher & subcommand routing | **Epic 1**: Story 1.1, 1.2 |
| `src/context.rs` | `cumulus.dotfiles.context.Context` | XDG paths (`~/.config`), active theme state & Sway socket discovery | **Epic 2**: Story 2.1 |
| `src/validate.rs` | `cumulus.dotfiles.validate.Validator` | Read-only desktop health check (`validate`) | **Epic 2**: Story 2.2 |
| `src/sdd.rs` & `src/collate.rs` | `cumulus.dotfiles.sdd.SpecDrivenDev` | Token-efficient AI development context generator (`sdd`) | **Epic 2**: Story 2.3 |
| `src/sysutils.rs` | `cumulus.dotfiles.sysutils.SysUtils` | Styled screen lock (`lock`), auto-idle daemon (`idle`), screen capture (`screenshot`) | **Epic 2**: Story 2.4 |
| `src/theme/` | `cumulus.dotfiles.theme.ThemeEngine` | Dynamic desktop theme & wallpaper switching (`theme`) | **Epic 3**: Story 3.1 |
| `src/refresh.rs` | `cumulus.dotfiles.refresh.RefreshEngine` | Live app reloads (`runtime-refresh`), GTK color sync (`os-colorscheme`), RGB sync (`rgb-theme`) | **Epic 3**: Story 3.2 |
| `src/pickers.rs` | `cumulus.dotfiles.pickers.WofiPickers` | Interactive Wofi GUI theme launcher (`theme-picker`) & keybindings cheatsheet (`whichkey`) | **Epic 3**: Story 3.3 |
| `src/autotiling.rs` | `cumulus.dotfiles.autotiling.AutotilingDaemon` | Sway IPC socket event listener daemon for Fibonacci spiral window autotiling (`autotiling`) | **Epic 4**: Story 4.1 |
| `src/maintenance.rs` | `cumulus.dotfiles.maintenance.Maintenance` | Tarball backup (`backup`), snapshot restore (`restore`), and git pull update (`update`) | **Epic 5**: Story 5.1, 5.2 |
| `src/install/deploy.rs` | `cumulus.dotfiles.install.DeployInstaller` | Machine setup installer (`install`/`deploy`) & symlink creation in `~/.local/bin` | **Epic 6**: Story 6.1 |
| `src/install/*.rs` | `cumulus.dotfiles.install.Installers` | Granular installers (`install-fonts`, `install-apps`, `install-browser`, `install-devops`, `install-zsh`, `install-sdkman`, `install-nvim`) | **Epic 6**: Story 6.2 |

---

## 4. Target Directory & Build Structure

```text
cumulus.dotfiles/
├── build.sbt                            # sbt project definition with sbt-native-image plugin
├── project/
│   ├── build.properties                 # sbt.version = 1.10.2
│   └── plugins.sbt                      # addSbtPlugin("io.github.davidgregory084" % "sbt-native-image" % "0.5.0")
└── src/
    └── main/
        └── scala/
            └── cumulus/
                ├── Main.scala           # Entrypoint: main(args: Array[String]): Unit
                └── dotfiles/
                    ├── context/
                    │   └── Context.scala
                    ├── error/
                    │   └── CumulusError.scala
                    ├── autotiling/
                    │   └── AutotilingDaemon.scala
                    ├── theme/
                    │   └── ThemeEngine.scala
                    ├── refresh/
                    │   └── RefreshEngine.scala
                    ├── sysutils/
                    │   └── SysUtils.scala
                    ├── maintenance/
                    │   └── Maintenance.scala
                    ├── install/
                    │   ├── DeployInstaller.scala
                    │   └── ToolInstallers.scala
                    ├── pickers/
                    │   └── WofiPickers.scala
                    ├── sdd/
                    │   └── SpecDrivenDev.scala
                    └── validate/
                        └── Validator.scala
```

---

## 5. Execution Roadmap & Next Steps

1. **Epic 1 Execution**: Build `build.sbt` with `sbt-native-image`, implement `cumulus.Main` dispatcher routing, and verify `sbt nativeImage` binary compilation.
2. **Epic 2 Execution**: Implement `Context` discovery object, `validate`, `sdd`, `lock`, `idle`, and `screenshot`.
3. **Epic 3 Execution**: Port `theme` engine, GTK/RGB color sync, and Wofi GUI pickers (`theme-picker`, `whichkey`).
4. **Epic 4 Execution**: Port Sway IPC Unix domain socket listener daemon (`autotiling`).
5. **Epic 5 Execution**: Port maintenance utilities (`backup`, `restore`, `update`).
6. **Epic 6 Execution**: Port deployment installer (`install`) and tool installers (`install-*`), generating symlinks in `~/.local/bin/`.
