# polyomino.dotfiles

Personal Sway/Wayland desktop configuration — native
Sway keybindings, wofi launcher, waybar status bar, kitty terminal, and zsh
shell config. Built in Scala 3 + GraalVM Native Image to be published to Maven Central or cloned onto a fresh machine.

## Contents

```
bootstrap.sh                      # System dependency & package installer
build.sbt                         # Scala 3 + GraalVM Native Image build specification
zsh/.zshrc                        # Thin oh-my-zsh bootstrap + modular config loader
zsh/zsh_config/                   # Modular zsh config (*.zsh)
config/sway/config                # Sway window manager config
config/wofi/                      # App launcher styling
config/waybar/                    # Status bar config & styling
config/kitty/                     # Terminal emulator config
src/                              # Scala 3 core engine & subcommand modules
.github/workflows/deploy.yml      # GitHub Actions CI/CD for Maven Central & GitHub Releases
```

## How it works

This repo is the source of truth for configuration files — they are **symlinked** into your `$HOME`:

```
~/.zshrc                          -> ~/polyomino.dotfiles/zsh/.zshrc
~/.config/polyomino/zsh_config      -> ~/polyomino.dotfiles/zsh/zsh_config
~/.config/sway                    -> ~/polyomino.dotfiles/config/sway
~/.config/wofi                    -> ~/polyomino.dotfiles/config/wofi
~/.config/waybar                  -> ~/polyomino.dotfiles/config/waybar
~/.config/kitty                   -> ~/polyomino.dotfiles/config/kitty
```

`polyomino install` handles creating those links safely:
1. If the target is already a symlink to the repo → skip.
2. If the target is a real file/dir → move it to `~/.polyomino_backup/<timestamp>/` first.
3. Runs `bootstrap.sh` to provision system packages (`pacman` / `apt-get`).
4. Runs `polyomino healthcheck` at the end to verify system health.

---

## Local Secrets & Environment Variables

If you have API keys, tokens, or environment variables that shouldn't be checked into version control, `polyomino` supports a local secrets file out of the box.

Simply create a file at `~/.polyomino.local.zsh` in your home directory:

```zsh
# ~/.polyomino.local.zsh
export GH_PAT="your_github_token"
export TF_VAR_google_credentials="..."
```

This file is automatically sourced by `zsh/zsh_config/40-environment.zsh` if it exists, keeping your credentials completely separate from the tracked git repository while still loading them on shell startup.

---

## Installation & Usage

### Quick Start (3 Commands)

**On a fresh machine:**

```bash
# Stage 1: Bootstrap (install Java & Coursier)
bash <(curl -fsSL https://raw.githubusercontent.com/petrolal/polyomino.dotfiles/master/bootstrap.sh)

# Stage 2: Install polyomino binary from Maven Central (resolves the latest release)
cs bootstrap io.github.petrolal::polyomino -o ~/.local/bin/polyomino

# Stage 3: Run installer (auto-clones this repo if needed, then full setup: symlinks, Homebrew, GitHub CLI, Coursier, Desktop Apps)
polyomino install
```

### Alternative: From Cloned Repository

```bash
git clone https://github.com/petrolal/polyomino.dotfiles.git ~/polyomino.dotfiles
cd ~/polyomino.dotfiles

# Stage 1: Bootstrap
./bootstrap.sh

# Stage 2: Install polyomino from Maven Central (resolves the latest release)
cs bootstrap io.github.petrolal::polyomino -o ~/.local/bin/polyomino

# Stage 3: Full setup
polyomino install
```

---

## How It Works (3-Stage Installation)

The installation is orchestrated by a Scala-based CLI tool:

```
Stage 1: Bootstrap (Java + Coursier setup)
    ↓ bash bootstrap.sh
Stage 2: Coursier (Download polyomino binary from Maven Central)
    ↓ cs bootstrap io.github.petrolal::polyomino -o ~/.local/bin/polyomino
Stage 3: Installer & Provisioning (Full system setup via Scala CLI)
    ↓ polyomino install
    ├── Symlink dotfiles (~/.config, ~/.zshrc)
    ├── Provision Homebrew, GitHub CLI (gh), Coursier (cs)
    ├── Install Desktop Apps, Fonts, TUI tools & Devops tooling
    └── Run System Healthcheck
    ↓
COMPLETE! All dotfiles symlinked and tooling configured
```

See [docs/INSTALLATION_FLOW.md](docs/INSTALLATION_FLOW.md) for detailed walkthrough.

---

## Building from Source

To build and test locally:

```bash
git clone https://github.com/petrolal/polyomino.dotfiles.git ~/polyomino.dotfiles
cd ~/polyomino.dotfiles

# Requirements: Java 21+ and sbt
# Install via: bash bootstrap.sh && cs bootstrap io.github.petrolal::polyomino -o ~/.local/bin/polyomino

# Compile & run unit tests
sbt test

# Compile GraalVM Native Image binary
sbt nativeImage

# Run installation from source
./target/native-image/polyomino install

# Or test interactive installer
./target/native-image/polyomino install --help
```

---

## Automated Deployment (GitHub Actions)

Releases are published automatically to **Maven Central** and **GitHub Releases** via GitHub Actions whenever a version tag is pushed:

```bash
git tag v0.1.0
git push origin v0.1.0
```

The workflow ([`.github/workflows/deploy.yml`](.github/workflows/deploy.yml)) performs:
1. Code checkout and GraalVM JDK 21 setup.
2. Maven Central release publication (`sbt ci-release`).
3. GraalVM Native Image compilation (`sbt nativeImage`).
4. GitHub Release creation with the `polyomino` native binary attached.

---

## Commands & Subcommands

All desktop automation, installers, maintenance, and system utilities are built inside a single binary (`polyomino`) with subcommand symlinks in `~/.local/bin/polyomino-*`:

| Command | Description |
|---|---|
| `polyomino install` | Deploy configs, run system package installer (`bootstrap.sh`), and execute `healthcheck` |
| `polyomino healthcheck` | Read-only sanity check of all symlinks, binaries, fonts, and PATH configurations |
| `polyomino theme` | Select desktop theme (custom palettes) & wallpaper mode |
| `polyomino wallpaper` | Swap the wallpaper within the active flavor (`next`/`prev`/`random`/`list`/`<name>`) — does not re-theme |
| `polyomino-theme-picker` | Wofi GUI picker for desktop theme selection (`Mod+Shift+T`) |
| `polyomino-wallpaper` | Wofi GUI picker for the active flavor's wallpapers (`Mod+Shift+P`) |
| `polyomino-whichkey` | Wofi cheatsheet of Sway keybindings (`Mod+Shift+?`) |
| `polyomino lock` | Screen lock styled to active theme (`Mod+Escape`) |
| `polyomino idle` | Swayidle daemon management (auto-lock, DPMS, suspend) |
| `polyomino screenshot` | Screen capture helper (`full`, `region`, `window`) |
| `polyomino autotiling` | Fibonacci spiral autotiling daemon for Sway |
| `polyomino backup` | Snapshot managed configs to a timestamped tarball |
| `polyomino restore` | Restore a configuration snapshot |
| `polyomino update` | Pull latest git changes and re-run installer |
| `polyomino sdd` | Spec-driven development framework CLI |
| `polyomino install-deps` | Install system & build dependencies (sbt, gcc, git, etc.) |
| `polyomino install-brew` | Install Homebrew package manager |
| `polyomino install-gh` | Install GitHub CLI (`gh`) |
| `polyomino install-coursier` | Install Coursier (`cs`) Scala application launcher |
| `polyomino install-tools` | Install TUI tools (spotify_player, bluetui, aerc) |
| `polyomino full-install` | Install system dependencies, Homebrew, gh, Coursier, apps, fonts, and tooling |

---

## Key Bindings

`$mod` = Mod4 (Super/Windows key). Full list available live via `polyomino-whichkey` (`Mod+Shift+?`).

| Keys | Action |
|---|---|
| `Mod+Return` | Open terminal (kitty) |
| `Mod+D` | App launcher (wofi drun) |
| `Mod+Shift+F` | File manager TUI (`yazi`) |
| `Mod+Shift+M` | Spotify player TUI (`spotify_player`) |
| `Mod+Shift+U` | Bluetooth manager TUI (`bluetui`) |
| `Mod+Shift+A` | Email client TUI (`aerc`) |
| `Mod+Shift+T` | Theme picker GUI (`polyomino-theme-picker`) |
| `Mod+Shift+P` | Wallpaper picker GUI for the active flavor (`polyomino-wallpaper`) |
| `Mod+F6` | Cycle to the next wallpaper in the active flavor |
| `Mod+F1`–`Mod+F4` | Apply flavor matriz / encruza / caravela / aruanda |
| `Mod+F5` | Cycle desktop flavor |
| `Mod+Shift+?` | Which-key cheatsheet (`polyomino-whichkey`) |
| `Mod+Shift+Q` | Kill focused window |
| `Mod+Shift+C` | Reload Sway config |
| `Mod+Escape` | Lock screen (`polyomino lock`) |
| `Print` | Screenshot — full screen |
| `Mod+Print` | Screenshot — select region |
| `Mod+Shift+Print` | Screenshot — focused window |
