# Bootstrap Setup Guide

The `bootstrap.sh` script is **Stage 1** of the 3-stage installation flow. It performs minimal system setup only.

For the complete installation workflow, see [INSTALLATION_FLOW.md](INSTALLATION_FLOW.md).

## What Gets Installed

The bootstrap script installs **only essential components**:

### Bootstrap Stage (Stage 1 of 3)

```bash
bash bootstrap.sh
```

Installs:
- **System Dependencies** - Sway, Waybar, Kitty, Wofi, etc.
- **Java 21 GraalVM** - For native image support
- **Coursier** - Scala dependency manager & app installer
- **SDKMan** - Scala Development Kit Manager (for Java management)

### Interactive Setup via cumulus CLI (Stage 3)

After bootstrap and Coursier install, run the interactive installer:

```bash
cumulus install
```

This Scala-based CLI handles:
- Desktop configuration
- Symlink deployment
- Optional tool installation
- System health checks

### System Dependencies

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

### Core Tools (Bootstrap)

- **Java 21 GraalVM** - Via SDKMan
- **Coursier** - Scala/JVM dependency manager

### Optional Tools (Post-Installation)

Installed after bootstrap via `./scripts/maintain-sdkman.sh install`:

- **Scala 3.5.2** - Scala language
- **sbt 1.9.9** - Scala build tool
- **Maven 3.9.6** - Java build tool
- **Gradle 8.5** - Modern build system
- **Kotlin 1.9.22** - JVM language
- **Groovy 4.0.17** - JVM language

## Quick Start

### 3-Stage Installation (Recommended)

```bash
# Stage 1: Bootstrap (Java + Coursier + system deps)
bash <(curl -fsSL https://raw.githubusercontent.com/petrolal/cumulus.dotfiles/master/bootstrap.sh)

# Stage 2: Download binary from Maven Central
cs install io.github.petrolal::cumulus:0.1.0 --name cumulus

# Stage 3: Interactive setup (Scala-based installer)
cumulus install
```

### Local Installation (From Clone)

```bash
git clone https://github.com/petrolal/cumulus.dotfiles.git ~/cumulus.dotfiles
cd ~/cumulus.dotfiles

# Stage 1
./bootstrap.sh

# Stage 2
cs install io.github.petrolal::cumulus:0.1.0 --name cumulus

# Stage 3
cumulus install
```

## Bootstrap Flow

```
1. Detect package manager (pacman/apt-get/dnf)
   ↓
2. Install system dependencies (requires sudo)
   ↓
3. Install SDKMan (Scala Development Kit Manager)
   ↓
4. Install Java 21 GraalVM via SDKMan
   ↓
5. Install Coursier (app installer & dependency manager)
   ↓
6. Add ~/.local/bin to PATH
   ↓
BOOTSTRAP COMPLETE!

Next: cs install io.github.petrolal::cumulus
```

## Environment Setup

### Add to ~/.bashrc or ~/.zshrc

```bash
# Coursier and cumulus binaries
export PATH="$HOME/.local/bin:$PATH"

# SDKMan (for Java/Scala/sbt management)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
```

### Reload Shell

```bash
source ~/.bashrc
# or
exec zsh
```

## Verify Installation

After bootstrap:

```bash
# Check Java
java -version

# Check Coursier
cs --version

# Verify PATH
echo $PATH | grep "$HOME/.local/bin"
```

## Next Steps

1. **Install cumulus binary:**
   ```bash
   cs install io.github.petrolal::cumulus:0.1.0 --name cumulus
   ```

2. **Run interactive installer:**
   ```bash
   cumulus install
   ```

3. **(Optional) Install additional development tools:**
   ```bash
   ./scripts/maintain-sdkman.sh install
   ```

## Troubleshooting

### "SDKMan: command not found"

Source SDKMan in current shell:

```bash
source $HOME/.sdkman/bin/sdkman-init.sh
java -version
```

Or add to shell config permanently:

```bash
cat >> ~/.bashrc << 'EOF'
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
EOF
source ~/.bashrc
```

### "Coursier not found"

Verify installation:

```bash
ls -la ~/.local/bin/cs
```

Install manually if missing:

```bash
mkdir -p ~/.local/bin
curl -fL https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz | gzip -d > ~/.local/bin/cs
chmod +x ~/.local/bin/cs
cs update
```

### "Java not found"

Check SDKMan:

```bash
source ~/.sdkman/bin/sdkman-init.sh
java -version
```

If still missing, install Java:

```bash
source ~/.sdkman/bin/sdkman-init.sh
sdk install java 21.0.1-graal --default
```

### "sudo password required"

This is normal! System package installation requires elevated privileges.

### "Cannot write to ~/.local/bin"

Create directory with proper permissions:

```bash
mkdir -p ~/.local/bin
chmod u+w ~/.local/bin
```

## Post-Installation

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

### Manage Additional Tools

```bash
./scripts/maintain-sdkman.sh install    # Interactive menu
./scripts/maintain-sdkman.sh check      # Status check
./scripts/maintain-sdkman.sh list       # List installed
./scripts/maintain-sdkman.sh update-all # Update everything
```

## See Also

- [INSTALLATION_FLOW.md](INSTALLATION_FLOW.md) - Complete 3-stage guide
- [COURSIER_SETUP.md](COURSIER_SETUP.md) - Coursier configuration
- [SDKMAN_MAINTENANCE.md](SDKMAN_MAINTENANCE.md) - Tool management
- [MANUAL_PUBLISHING.md](MANUAL_PUBLISHING.md) - Publishing guide
- [README.md](README.md) - Project overview
