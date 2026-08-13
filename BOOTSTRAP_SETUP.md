# Bootstrap Setup Guide

The `bootstrap.sh` script now provides a complete development environment setup including Scala, GraalVM, and Coursier installation.

## What Gets Installed

The bootstrap script automates the installation of:

### 1. System Dependencies
```bash
# Arch Linux (pacman)
sbt, jdk-openjdk, gcc, git, curl, fontconfig, zsh, tar, unzip
sway, waybar, kitty, wofi, swaylock, swayidle, grim, slurp
brightnessctl, libpulse, chromium, docker, terraform, kubectl
helm, neovim, ttf-jetbrains-mono-nerd, mako

# Ubuntu/Debian (apt-get)
build-essential, default-jdk, sbt, git, curl, fontconfig, zsh, tar, unzip
sway, waybar, kitty, wofi, swaylock, swayidle, grim, slurp
brightnessctl, pulseaudio-utils, firefox, docker.io, helm, neovim
fonts-jetbrains-mono, mako
```

### 2. SDKMan (Scala Development Kit Manager)
- Downloads to `~/.sdkman`
- Manages multiple Java, Scala, and sbt versions
- Isolated from system package managers

### 3. Development Tools via SDKMan
- **Java 21 GraalVM** - For native image compilation
- **Scala 3.5.2** - Latest Scala version
- **sbt 1.9.9** - Scala build tool

### 4. Coursier
- Downloads to `~/.local/bin/cs`
- Enables `cs install` command
- Bootstraps dependency cache

### 5. cumulus CLI
- Compiles native image using GraalVM
- Installs to `~/.local/bin/cumulus`
- Deploys configuration files and symlinks

## Quick Start

### Fresh Machine Installation

```bash
# One-liner for fresh machine
bash <(curl -fsSL https://raw.githubusercontent.com/petrolal/cumulus.dotfiles/master/bootstrap.sh)

# Or clone and run locally
git clone https://github.com/petrolal/cumulus.dotfiles.git ~/cumulus.dotfiles
cd ~/cumulus.dotfiles
./bootstrap.sh
```

### What Happens During Bootstrap

```
1. Detect package manager (pacman/apt-get/dnf/unknown)
   ↓
2. Install system dependencies (requires sudo)
   ↓
3. Enable mako notification daemon
   ↓
4. Install SDKMan (Scala Development Kit Manager)
   ↓
5. Install Java 21 GraalVM via SDKMan
   ↓
6. Install Scala 3.5.2 via SDKMan
   ↓
7. Install sbt 1.9.9 via SDKMan
   ↓
8. Install Coursier (cs command)
   ↓
9. Build GraalVM native image (sbt nativeImage)
   ↓
10. Install cumulus CLI to ~/.local/bin/cumulus
    ↓
11. Run cumulus install (deploy configs, create symlinks)
    ↓
12. Run cumulus healthcheck (verify installation)
    ↓
13. Ask if you want to reboot
```

## Environment Setup

After bootstrap completes, you need to load SDKMan in your shell:

### Add to ~/.zshrc (already included in cumulus config)

```bash
# SDKMan initialization
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
```

### Verify Installation

```bash
# Check SDKMan
$HOME/.sdkman/bin/sdkman-init.sh version

# Check Java (GraalVM)
source $HOME/.sdkman/bin/sdkman-init.sh
java -version

# Check Scala
scala -version

# Check sbt
sbt --version

# Check Coursier
cs --version

# Check cumulus
cumulus --version
```

## Troubleshooting

### "SDKMan: command not found"

SDKMan needs to be sourced in your current shell session:

```bash
source $HOME/.sdkman/bin/sdkman-init.sh
java -version
```

Or add to `~/.bashrc` or `~/.zshrc`:

```bash
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
```

### "Java 21 GraalVM not found"

```bash
# Verify SDKMan is installed
ls -la $HOME/.sdkman

# Source SDKMan
source $HOME/.sdkman/bin/sdkman-init.sh

# Install Java manually
sdk install java 21.0.1-graal --default

# Check
java -version
```

### "sbt: command not found"

```bash
# Source SDKMan first
source $HOME/.sdkman/bin/sdkman-init.sh

# Install sbt manually
sdk install sbt 1.9.9 --default

# Check
sbt --version
```

### "Coursier not found"

```bash
# Check installation
ls -la ~/.local/bin/cs

# If missing, reinstall
mkdir -p ~/.local/bin
curl -fL https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz | gzip -d > ~/.local/bin/cs
chmod +x ~/.local/bin/cs

# Add to PATH if not already there
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

### "sudo password required" (during system package install)

The bootstrap script will prompt for your sudo password when installing system packages. This is required for:

```bash
# Arch Linux
sudo pacman -S --needed --noconfirm [packages]

# Ubuntu/Debian
sudo apt-get install -y [packages]
```

### Native Image Build Fails

If `sbt nativeImage` fails:

```bash
# 1. Ensure GraalVM Java 21 is active
source $HOME/.sdkman/bin/sdkman-init.sh
java -version  # Should show GraalVM

# 2. Clean and rebuild
cd ~/cumulus.dotfiles
sbt clean compile
sbt nativeImage

# 3. Check errors in detail
sbt -v nativeImage  # Verbose output
```

## Manual Installation Steps

If you prefer to install components manually:

### SDKMan Only

```bash
# Install SDKMan
curl -s "https://get.sdkman.io" | bash
source $HOME/.sdkman/bin/sdkman-init.sh

# Install specific versions
sdk install java 21.0.1-graal
sdk install scala 3.5.2
sdk install sbt 1.9.9
```

### Coursier Only

```bash
mkdir -p ~/.local/bin

# Linux
curl -fL https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz | gzip -d > ~/.local/bin/cs

# macOS
curl -fL https://github.com/coursier/launchers/raw/master/cs-x86_64-apple-darwin.gz | gzip -d > ~/.local/bin/cs

chmod +x ~/.local/bin/cs
cs update
```

### System Dependencies Only

```bash
# Arch Linux
sudo pacman -S sbt jdk-openjdk gcc git curl fontconfig zsh tar unzip sway waybar kitty wofi swaylock swayidle grim slurp brightnessctl libpulse chromium docker terraform kubectl helm neovim ttf-jetbrains-mono-nerd mako

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y build-essential default-jdk sbt git curl fontconfig zsh tar unzip sway waybar kitty wofi swaylock swayidle grim slurp brightnessctl pulseaudio-utils firefox docker.io helm neovim fonts-jetbrains-mono mako
```

## Path Setup

After bootstrap, ensure these directories are in your PATH:

```bash
# ~/.local/bin contains: cumulus, cs
echo $PATH | grep -q "$HOME/.local/bin" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# SDKMan adds java, scala, sbt to PATH automatically
source $HOME/.sdkman/bin/sdkman-init.sh
echo $PATH
```

## Updating Components

After initial bootstrap, you can update individual components:

### Update SDKMan & Java

```bash
source $HOME/.sdkman/bin/sdkman-init.sh
sdk selfupdate
sdk list java
sdk install java 21.0.5-graal  # Newer version
sdk default java 21.0.5-graal
```

### Update Scala

```bash
sdk list scala
sdk install scala 3.6.0  # Newer version
sdk default scala 3.6.0
```

### Update sbt

```bash
sdk list sbt
sdk install sbt 1.10.0  # Newer version
sdk default sbt 1.10.0
```

### Update Coursier

```bash
# Check for updates
cs update

# Or reinstall latest
rm ~/.local/bin/cs
mkdir -p ~/.local/bin
curl -fL https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz | gzip -d > ~/.local/bin/cs
chmod +x ~/.local/bin/cs
```

## Custom Bootstrap

To customize bootstrap behavior, you can:

### Skip Reboot Prompt

```bash
# Don't ask to reboot at the end
SKIP_REBOOT=1 ./bootstrap.sh
```

### Run in Headless Mode

```bash
# For CI/CD or automated setup
NO_INTERACTIVE=1 ./bootstrap.sh
```

## See Also

- [SDKMan Documentation](https://sdkman.io/)
- [Coursier Documentation](https://get-coursier.io/)
- [GraalVM Native Image](https://www.graalvm.org/latest/reference-manual/native-image/)
- [Scala 3 Documentation](https://docs.scala-lang.org/scala3/)
- [MANUAL_PUBLISHING.md](MANUAL_PUBLISHING.md) - Local publishing guide
- [COURSIER_SETUP.md](COURSIER_SETUP.md) - Coursier installation guide
