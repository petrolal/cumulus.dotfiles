# cumulus.dotfiles

Personal Sway/Wayland desktop configuration — AWS Cloud theme, native
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
~/.zshrc                          -> ~/cumulus.dotfiles/zsh/.zshrc
~/.config/cumulus/zsh_config      -> ~/cumulus.dotfiles/zsh/zsh_config
~/.config/sway                    -> ~/cumulus.dotfiles/config/sway
~/.config/wofi                    -> ~/cumulus.dotfiles/config/wofi
~/.config/waybar                  -> ~/cumulus.dotfiles/config/waybar
~/.config/kitty                   -> ~/cumulus.dotfiles/config/kitty
```

`cumulus install` handles creating those links safely:
1. If the target is already a symlink to the repo → skip.
2. If the target is a real file/dir → move it to `~/.cumulus_backup/<timestamp>/` first.
3. Runs `bootstrap.sh` to provision system packages (`pacman` / `apt-get`).
4. Runs `cumulus healthcheck` at the end to verify system health.

---

## Installation & Usage

### 1. Installed via Maven Central (Coursier)

If downloading the globally installed dependency from Maven Central:

```bash
# Download and install cumulus binary globally via Coursier
cs install com.cumulus::cumulus:0.1.0 --name cumulus

# Execute installation (runs bootstrap.sh and cumulus healthcheck)
cumulus install
```

### 2. Quick One-Liner (Fresh Machine)

On a brand-new machine:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/petrolal/cumulus.dotfiles/master/bootstrap.sh)
```

---

## Building from Source

```bash
git clone https://github.com/petrolal/cumulus.dotfiles.git ~/cumulus.dotfiles
cd ~/cumulus.dotfiles

# Compile & run unit tests
sbt test

# Compile GraalVM Native Image binary
sbt nativeImage

# Run installation and healthcheck
./target/native-image/cumulus install
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
4. GitHub Release creation with the `cumulus` native binary attached.

---

## Commands & Subcommands

All desktop automation, installers, maintenance, and system utilities are built inside a single binary (`cumulus`) with subcommand symlinks in `~/.local/bin/cumulus-*`:

| Command | Description |
|---|---|
| `cumulus install` | Deploy configs, run system package installer (`bootstrap.sh`), and execute `healthcheck` |
| `cumulus healthcheck` | Read-only sanity check of all symlinks, binaries, fonts, and PATH configurations |
| `cumulus theme` | Select desktop cloud theme (`aws`, `azure`, `gcp`, `oci`) & wallpaper mode |
| `cumulus-theme-picker` | Wofi GUI picker for desktop theme selection (`Mod+Shift+T`) |
| `cumulus-whichkey` | Wofi cheatsheet of Sway keybindings (`Mod+Shift+?`) |
| `cumulus lock` | Screen lock styled to active theme (`Mod+Escape`) |
| `cumulus idle` | Swayidle daemon management (auto-lock, DPMS, suspend) |
| `cumulus screenshot` | Screen capture helper (`full`, `region`, `window`) |
| `cumulus autotiling` | Fibonacci spiral autotiling daemon for Sway |
| `cumulus backup` | Snapshot managed configs to a timestamped tarball |
| `cumulus restore` | Restore a configuration snapshot |
| `cumulus update` | Pull latest git changes and re-run installer |
| `cumulus sdd` | Spec-driven development framework CLI |
| `cumulus install-all` | Install system dependencies, apps, fonts, and developer tools |

---

## Key Bindings

`$mod` = Mod4 (Super/Windows key). Full list available live via `cumulus-whichkey` (`Mod+Shift+?`).

| Keys | Action |
|---|---|
| `Mod+Return` | Open terminal (kitty) |
| `Mod+D` | App launcher (wofi drun) |
| `Mod+Shift+T` | Theme picker GUI (`cumulus-theme-picker`) |
| `Mod+Shift+?` | Which-key cheatsheet (`cumulus-whichkey`) |
| `Mod+Shift+Q` | Kill focused window |
| `Mod+Shift+C` | Reload Sway config |
| `Mod+Escape` | Lock screen (`cumulus lock`) |
| `Print` | Screenshot — full screen |
| `Mod+Print` | Screenshot — select region |
| `Mod+Shift+Print` | Screenshot — focused window |
