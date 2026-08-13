# SDKMan Maintenance Guide

This guide covers maintaining existing SDKMan installations, updating tools, and managing multiple versions.

## Quick Start

```bash
# Check status
./scripts/maintain-sdkman.sh check

# Update everything
./scripts/maintain-sdkman.sh update-all

# Upgrade SDKMan itself
./scripts/maintain-sdkman.sh upgrade

# List current versions
./scripts/maintain-sdkman.sh list
```

## Available Commands

### Status & Information

```bash
# Check SDKMan installation
./scripts/maintain-sdkman.sh check

# List currently installed versions
./scripts/maintain-sdkman.sh list

# Show available versions for a tool
./scripts/maintain-sdkman.sh available java
./scripts/maintain-sdkman.sh available scala
./scripts/maintain-sdkman.sh available sbt
```

### Upgrading Tools

```bash
# Upgrade SDKMan itself
./scripts/maintain-sdkman.sh upgrade

# Update Java (default: 21.0.1-graal)
./scripts/maintain-sdkman.sh update-java
./scripts/maintain-sdkman.sh update-java 21.0.5-graal  # Specific version

# Update Scala (default: 3.5.2)
./scripts/maintain-sdkman.sh update-scala
./scripts/maintain-sdkman.sh update-scala 3.6.0  # Specific version

# Update sbt (default: 1.9.9)
./scripts/maintain-sdkman.sh update-sbt
./scripts/maintain-sdkman.sh update-sbt 1.10.0  # Specific version

# Update all at once
./scripts/maintain-sdkman.sh update-all
```

### Maintenance

```bash
# Show guidance for cleaning old versions
./scripts/maintain-sdkman.sh clean

# Reset SDKMan (backup existing, install fresh)
./scripts/maintain-sdkman.sh reset

# Show help
./scripts/maintain-sdkman.sh help
```

## Common Workflows

### Regular Maintenance (Monthly)

```bash
# Check for updates
./scripts/maintain-sdkman.sh check

# Upgrade SDKMan
./scripts/maintain-sdkman.sh upgrade

# List versions
./scripts/maintain-sdkman.sh list

# Update if needed
./scripts/maintain-sdkman.sh update-all
```

### Update Single Tool

```bash
# Check available versions
./scripts/maintain-sdkman.sh available java

# Install specific version
./scripts/maintain-sdkman.sh update-java 21.0.5-graal

# Verify
java -version
```

### Install Multiple Java Versions

```bash
# Install additional version without changing default
bash -c "
  source ~/.sdkman/bin/sdkman-init.sh
  sdk install java 17.0.8-graal  # Install without --default
  sdk list java  # Show all installed versions
"

# Switch between versions
bash -c "
  source ~/.sdkman/bin/sdkman-init.sh
  sdk use java 17.0.8-graal  # Temporary switch
  java -version
  sdk default java 21.0.1-graal  # Make default
"
```

### Clean Old Versions

Old versions accumulate in `~/.sdkman/candidates/`. To clean up:

```bash
# List old versions
ls -la ~/.sdkman/candidates/java/
ls -la ~/.sdkman/candidates/scala/
ls -la ~/.sdkman/candidates/sbt/

# Remove specific old version
rm -rf ~/.sdkman/candidates/java/20.0.0-graal

# Get current defaults first!
bash -c "
  source ~/.sdkman/bin/sdkman-init.sh
  sdk current  # Note the versions before deleting
"

# Then remove others
rm -rf ~/.sdkman/candidates/java/*  # Remove all except current (use with caution!)
```

## Environment Setup

### Load SDKMan in Shell

Add to `~/.bashrc` or `~/.zshrc`:

```bash
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
```

### Custom Installation Path

By default, SDKMan installs to `~/.sdkman`. To use custom path:

```bash
# Install to custom location
export SDKMAN_DIR="/opt/sdkman"
curl -s "https://get.sdkman.io" | bash

# Or run maintenance script with custom path
SDKMAN_DIR=/opt/sdkman ./scripts/maintain-sdkman.sh check
```

## Bootstrap Integration

### Automatic Installation

The bootstrap script now supports SDKMan upgrade:

```bash
# Install fresh or upgrade if exists
SDKMAN_UPGRADE=true ./bootstrap.sh

# Regular bootstrap (no upgrade)
./bootstrap.sh
```

### Bootstrap Flow

1. **Detect existing SDKMan** → Use existing, optionally upgrade
2. **Install if missing** → Fresh installation
3. **Install/verify tools** → Java, Scala, sbt via SDKMan

## Troubleshooting

### "SDKMan: command not found"

SDKMan must be sourced in your shell session:

```bash
source ~/.sdkman/bin/sdkman-init.sh
sdk version
```

Or add to shell config:

```bash
echo 'export SDKMAN_DIR="$HOME/.sdkman"' >> ~/.bashrc
echo '[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"' >> ~/.bashrc
```

### "Java version mismatch"

Different tools may use different Java versions. Check and fix:

```bash
# See current versions
bash -c "
  source ~/.sdkman/bin/sdkman-init.sh
  sdk current
"

# Set Java as default
bash -c "
  source ~/.sdkman/bin/sdkman-init.sh
  sdk default java 21.0.1-graal
"

# Verify
java -version
```

### "Cannot install version"

Network issues or invalid version. Try:

```bash
# Check available versions first
./scripts/maintain-sdkman.sh available java

# Retry with valid version
./scripts/maintain-sdkman.sh update-java 21.0.5-graal

# If still failing, check network
curl -s https://api.sdkman.io/2/candidates/java/all | jq .[0:5]
```

### "SDKMan cache corrupted"

Reset SDKMan to fix:

```bash
# Backup existing
cp -r ~/.sdkman ~/.sdkman.backup

# Reset
./scripts/maintain-sdkman.sh reset

# Or manually
rm -rf ~/.sdkman
curl -s "https://get.sdkman.io" | bash
source ~/.sdkman/bin/sdkman-init.sh
```

## Advanced Usage

### Scripted Updates (CI/CD)

```bash
#!/bin/bash
set -euo pipefail

export SDKMAN_DIR="$HOME/.sdkman"

# Non-interactive update
bash -c "
  source $SDKMAN_DIR/bin/sdkman-init.sh
  sdk selfupdate force
  sdk install java 21.0.1-graal --default
  sdk install scala 3.5.2 --default
  sdk install sbt 1.9.9 --default
  sdk current
"
```

### Version Matrix

Track which versions work together:

```bash
# Recommended combinations
Java 21 GraalVM + Scala 3.5.2 + sbt 1.9.9  ← Current default
Java 17 GraalVM + Scala 3.4.0 + sbt 1.8.3
Java 11 OpenJDK + Scala 2.13.12 + sbt 1.7.3
```

### Parallel Installations

SDKMan supports multiple versions installed simultaneously:

```bash
bash -c "
  source ~/.sdkman/bin/sdkman-init.sh

  # Install multiple Scala versions
  sdk install scala 3.5.2  # Will be default
  sdk install scala 3.4.0  # Keep old version
  sdk install scala 2.13.12  # Legacy support

  # List all
  sdk list scala

  # Switch temporarily
  sdk use scala 3.4.0
  scala -version

  # Switch back
  sdk use scala 3.5.2
"
```

## Performance Tips

### Faster SDK Switching

```bash
# Pre-load SDKMan for faster commands
bash -c "
  source ~/.sdkman/bin/sdkman-init.sh
  # Commands here run with SDKMan active
  sdk current
  java -version
  sbt --version
"
```

### Update Caching

SDKMan caches downloaded versions. Locations:

- Installs: `~/.sdkman/candidates/`
- Cache: `~/.sdkman/var/`

To clear cache safely:

```bash
# Safe: Only remove download cache
rm -rf ~/.sdkman/var/cache/

# Note installed versions before cleanup
ls ~/.sdkman/candidates/java/
ls ~/.sdkman/candidates/scala/
ls ~/.sdkman/candidates/sbt/
```

## See Also

- [SDKMan Official Docs](https://sdkman.io/)
- [Java LTS Versions](https://sdkman.io/jdks)
- [Scala Releases](https://sdkman.io/sdks/scala)
- [sbt Releases](https://sdkman.io/sdks/sbt)
- [BOOTSTRAP_SETUP.md](BOOTSTRAP_SETUP.md) - Bootstrap configuration
- [bootstrap.sh](bootstrap.sh) - Bootstrap script with SDKMan support
