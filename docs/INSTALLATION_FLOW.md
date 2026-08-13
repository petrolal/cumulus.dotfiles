# Installation Flow Guide

Complete guide to installing cumulus.dotfiles using the three-stage installation process.

## Overview

The installation uses a **3-stage flow**:

```
Stage 1: Bootstrap (Java + Coursier)
    ↓
    bash bootstrap.sh
    ↓
Stage 2: Coursier (Download cumulus binary)
    ↓
    cs install io.github.petrolal::cumulus:0.1.0
    ↓
Stage 3: Interactive Installer (Full system setup)
    ↓
    cumulus install [options]
    ↓
    COMPLETE!
```

## Quick Start (3 Commands)

```bash
# 1. Bootstrap: Install Java & Coursier
bash <(curl -fsSL https://raw.githubusercontent.com/petrolal/cumulus.dotfiles/master/bootstrap.sh)

# 2. Install cumulus binary from Maven Central
cs install io.github.petrolal::cumulus:0.1.0 --name cumulus

# 3. Run interactive installer
cumulus install
```

## Detailed Installation

### Stage 1: Bootstrap (5-10 minutes)

The bootstrap script performs **minimal setup only**:

```bash
# One-liner
bash <(curl -fsSL https://raw.githubusercontent.com/petrolal/cumulus.dotfiles/master/bootstrap.sh)

# Or from cloned repo
git clone https://github.com/petrolal/cumulus.dotfiles.git ~/cumulus.dotfiles
cd ~/cumulus.dotfiles
./bootstrap.sh
```

**What bootstrap.sh does:**
1. Detects your package manager (pacman, apt-get, dnf)
2. Installs system dependencies (Sway, Waybar, Kitty, etc.)
3. Installs Java 21 GraalVM (via SDKMan)
4. Installs Coursier (dependency manager & app installer)
5. Adds `~/.local/bin` to PATH

**What bootstrap.sh does NOT do:**
- ❌ Does NOT install SDKMan (only Java is needed)
- ❌ Does NOT install Scala, sbt, Maven, Gradle (not needed yet)
- ❌ Does NOT create symlinks
- ❌ Does NOT deploy dotfiles

### Stage 2: Install cumulus Binary (1-2 minutes)

Once Java & Coursier are installed, download the cumulus CLI:

```bash
# Install from Maven Central
cs install io.github.petrolal::cumulus:0.1.0 --name cumulus

# Or latest version
cs install io.github.petrolal::cumulus --name cumulus

# Verify installation
cumulus --version
```

Coursier automatically:
- Downloads JAR from Maven Central
- Resolves dependencies
- Creates launch script in `~/.local/share/coursier/bin/cumulus`
- Updates PATH (if configured)

### Stage 3: Interactive Installer (5-15 minutes)

Run the interactive Scala-based installer:

```bash
cumulus install
```

This launches an interactive menu with prompts for:

**System Dependencies:**
- Confirm system packages are installed
- Install any missing packages

**Desktop Environment:**
- Choose desktop theme (AWS, Azure, GCP, OCI)
- Choose wallpaper mode

**Configuration Deployment:**
- Symlink dotfiles to home directory
- Create subcommand aliases (~/.local/bin/cumulus-*)
- Deploy configuration files

**System Health Check:**
- Verify all symlinks
- Check PATH configuration
- Validate installed tools

## Installation Flow Diagram

```
┌─────────────────────────────────────────┐
│ STAGE 1: BOOTSTRAP                      │
├─────────────────────────────────────────┤
│ bash bootstrap.sh                       │
│ - Install system packages               │
│ - Install Java (GraalVM)                │
│ - Install Coursier                      │
│ - Setup PATH                            │
└────────────────┬────────────────────────┘
                 │
                 ↓
         ✓ Java ready
         ✓ Coursier ready
         ✓ PATH configured
                 │
                 ↓
┌─────────────────────────────────────────┐
│ STAGE 2: COURSIER                       │
├─────────────────────────────────────────┤
│ cs install io.github.petrolal::cumulus  │
│ - Download JAR from Maven Central       │
│ - Resolve dependencies                  │
│ - Create launch script                  │
└────────────────┬────────────────────────┘
                 │
                 ↓
         ✓ cumulus CLI ready
                 │
                 ↓
┌─────────────────────────────────────────┐
│ STAGE 3: INTERACTIVE INSTALLER          │
├─────────────────────────────────────────┤
│ cumulus install [options]               │
│                                         │
│ Interactive Scala-based installer:      │
│ - Prompt for configuration choices      │
│ - Deploy symlinks & dotfiles            │
│ - Run system health check               │
│ - Complete full setup                   │
└────────────────┬────────────────────────┘
                 │
                 ↓
        ✓ Installation Complete!
        ✓ Desktop Ready
        ✓ All symlinks deployed
        ✓ All tools configured
```

## Interactive Installation Options

The `cumulus install` command supports various options:

```bash
# Full interactive installation (default)
cumulus install

# Deploy only symlinks (skip system installation)
cumulus install --links-only

# Quiet mode (non-interactive, skip prompts)
cumulus install --quiet

# Verbose logging
cumulus install -v

# Custom dotfiles path
cumulus install --dotfiles ~/my-custom-dotfiles
```

## Environment Setup

After installation, ensure PATH is configured:

### For bash/zsh:

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# Coursier and cumulus
export PATH="$HOME/.local/bin:$PATH"

# SDKMan (if you installed it)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
```

Then reload shell:

```bash
source ~/.bashrc
# or
exec zsh
```

## Verification

After installation, verify everything works:

```bash
# Check cumulus is installed
cumulus --version

# Run health check
cumulus healthcheck

# List available commands
cumulus --help

# Test a command
cumulus-theme --help
```

## Stage 1: Bootstrap Details

### What Gets Installed

The bootstrap script installs **only essential components**:

- **System Dependencies** - Sway, Waybar, Kitty, Wofi, Swaylock, Swayidle, Grim, Slurp, etc.
- **Java 21 GraalVM** - For native image support
- **Coursier** - Scala dependency manager & app installer
- **SDKMan** - Scala Development Kit Manager (for Java management)

### System Dependencies by Package Manager

**Arch Linux (pacman):**
```
sway, waybar, kitty, wofi, swaylock, swayidle, grim, slurp
brightnessctl, libpulse, mako, firefox, chromium, neovim
```

**Ubuntu/Debian (apt-get):**
```
sway, waybar, kitty, wofi, swaylock, swayidle, grim, slurp
brightnessctl, pulseaudio-utils, mako, firefox, neovim
```

### Bootstrap Environment Setup

After running `bootstrap.sh`, add to `~/.bashrc` or `~/.zshrc`:

```bash
# Coursier and cumulus binaries
export PATH="$HOME/.local/bin:$PATH"

# SDKMan (for Java/Scala/sbt management)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
```

Then reload your shell:

```bash
source ~/.bashrc  # or exec zsh
```

### Verify Bootstrap Completed

```bash
# Check Java
java -version

# Check Coursier
cs --version

# Verify PATH
echo $PATH | grep "$HOME/.local/bin"
```

## Stage 2: Coursier Configuration

### How Coursier Works

1. **JAR published to Maven Central** → Coursier discovers it
2. **Main class specified** → Coursier creates launch script
3. **Dependencies resolved** → Coursier downloads all deps
4. **Executable installed** → Binary available in `~/.local/share/coursier/bin/`

### Installation Methods

**Standard (recommended):**
```bash
cs install io.github.petrolal::cumulus:0.1.0 --name cumulus
```

**Latest version:**
```bash
cs install io.github.petrolal::cumulus --name cumulus
```

**Fat JAR (for testing before Maven Central sync):**
```bash
cd ~/cumulus.dotfiles
sbt assembly
cs install file://$(pwd)/target/scala-3.5.2/cumulus-0.1.0-assembly.jar --name cumulus
```

### Coursier Configuration

**Cache location:**
```bash
~/.cache/coursier/  # Linux/Mac
~/AppData/Local/Coursier/Cache  # Windows
```

**View installed apps:**
```bash
cs list --installed
ls -la ~/.local/share/coursier/bin/
```

**Customize installation location:**
```bash
cs install io.github.petrolal::cumulus:0.1.0 --install-dir ~/my-bin
export PATH="~/my-bin:$PATH"
```

## Troubleshooting

### "cumulus: command not found"

PATH is not configured. Add to shell config:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload:

```bash
source ~/.bashrc  # or exec zsh
```

### "Java not found"

Java installation failed. Install manually:

```bash
# Option 1: Via SDKMan
curl -s "https://get.sdkman.io" | bash
source ~/.sdkman/bin/sdkman-init.sh
sdk install java 21.0.1-graal --default

# Option 2: Via package manager
sudo pacman -S jdk-openjdk  # Arch
# or
sudo apt-get install -y default-jdk  # Ubuntu/Debian
```

### "Coursier not found"

Coursier installation failed. Install manually:

```bash
mkdir -p ~/.local/bin

# Linux
curl -fL https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz | gzip -d > ~/.local/bin/cs

# macOS
curl -fL https://github.com/coursier/launchers/raw/master/cs-x86_64-apple-darwin.gz | gzip -d > ~/.local/bin/cs

chmod +x ~/.local/bin/cs
cs update
```

### "Cannot download cumulus from Maven Central"

Maven Central deployment may be in progress (10-30 mins). Try:

```bash
# Wait a few minutes, then try again
cs install io.github.petrolal::cumulus:0.1.0

# Or install from local JAR if available
cd ~/cumulus.dotfiles
sbt assembly
cs install file://$(pwd)/target/scala-3.5.2/cumulus-0.1.0-assembly.jar --name cumulus
```

### "cumulus install fails during system dependency installation"

System packages failed to install. Options:

1. **Install manually:**
   ```bash
   # Arch Linux
   sudo pacman -S sway waybar kitty wofi swaylock swayidle grim slurp brightnessctl libpulse mako firefox neovim

   # Ubuntu/Debian
   sudo apt-get install -y sway waybar kitty wofi swaylock swayidle grim slurp brightnessctl pulseaudio-utils mako firefox neovim
   ```

2. **Run installer again:**
   ```bash
   cumulus install
   ```

### "SDKMan: command not found"

Source SDKMan in current shell:

```bash
source $HOME/.sdkman/bin/sdkman-init.sh
java -version
```

Or add to shell config permanently (see Environment Setup above).

## Advanced Installation Options

### Install Without System Packages

If you prefer to install system packages manually:

```bash
# Skip system package installation
CUMULUS_SKIP_SYSTEM_DEPS=1 cumulus install
```

### Install to Custom Location

```bash
# Install cumulus to custom location
cs install io.github.petrolal::cumulus:0.1.0 --install-dir ~/my-local-bin/

# Or use custom Coursier cache
export COURSIER_CACHE=~/.coursier-custom
cs install io.github.petrolal::cumulus:0.1.0
```

### CI/CD Automated Installation

```bash
#!/bin/bash
set -euo pipefail

# Automated bootstrap
bash <(curl -fsSL https://raw.githubusercontent.com/petrolal/cumulus.dotfiles/master/bootstrap.sh)

# Non-interactive installation
export PATH="$HOME/.local/bin:$PATH"
cs install io.github.petrolal::cumulus:0.1.0 --name cumulus
cumulus install --quiet
```

### Development Installation (From Source)

To install from source for development:

```bash
# Clone repository
git clone https://github.com/petrolal/cumulus.dotfiles.git ~/cumulus.dotfiles
cd ~/cumulus.dotfiles

# Build from source
sbt nativeImage

# Install locally
mkdir -p ~/.local/bin
cp target/native-image/cumulus ~/.local/bin/

# Run installer
cumulus install
```

## Post-Installation Management

### Update SDKMan & Java

```bash
source ~/.sdkman/bin/sdkman-init.sh
sdk selfupdate
sdk install java 21.0.5-graal --default
```

### Update Coursier

```bash
cs update

# Or reinstall latest
rm ~/.local/bin/cs
curl -fL https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz | gzip -d > ~/.local/bin/cs
chmod +x ~/.local/bin/cs
```

### Manage Additional Development Tools

```bash
./scripts/maintain-sdkman.sh install    # Interactive menu
./scripts/maintain-sdkman.sh check      # Status check
./scripts/maintain-sdkman.sh list       # List installed
./scripts/maintain-sdkman.sh update-all # Update everything
```

## Installation Timeline

**On a fresh machine (from scratch):**

| Stage | Time | What's Happening |
|-------|------|-----------------|
| Bootstrap | 5-10 min | Installing system packages, Java, Coursier |
| Download | 1-2 min | Downloading cumulus from Maven Central |
| Deploy | 5-15 min | Interactive setup, symlink creation, health check |
| **Total** | **10-25 min** | **Depends on network & system speed** |

**On a machine with system packages already installed:**

| Stage | Time | What's Happening |
|-------|------|-----------------|
| Bootstrap | 2-3 min | Installing Java, Coursier |
| Download | 1-2 min | Downloading cumulus from Maven Central |
| Deploy | 2-5 min | Deploy symlinks, health check |
| **Total** | **5-10 min** | **Much faster!** |

## See Also

- [PUBLISHING.md](PUBLISHING.md) - Publishing to Maven Central
- [README.md](../README.md) - Project overview
- [SDKMAN_MAINTENANCE.md](SDKMAN_MAINTENANCE.md) - Tool management
