# Documentation Index

Complete guide to all cumulus.dotfiles documentation.

## Getting Started

### For End Users

**Start here:** [INSTALLATION_FLOW.md](INSTALLATION_FLOW.md)
- 3-stage installation overview
- Quick start guide (3 commands)
- Detailed walkthrough of each stage
- Troubleshooting

**Quick reference:** [README.md](README.md)
- Project overview
- Commands and key bindings
- What gets installed
- Quick installation

### For Development

**Building from source:** [README.md](README.md#building-from-source)
- Clone repository
- Build with sbt
- Install from source

**Publishing to Maven Central:** [MANUAL_PUBLISHING.md](MANUAL_PUBLISHING.md)
- Setup Sonatype account
- Configure GPG keys
- Manual publishing commands
- CI/CD integration

## Installation Guides

| Document | Purpose | Audience |
|----------|---------|----------|
| [INSTALLATION_FLOW.md](INSTALLATION_FLOW.md) | 3-stage installation workflow | Everyone |
| [BOOTSTRAP_SETUP.md](BOOTSTRAP_SETUP.md) | Stage 1: Bootstrap (Java + Coursier) | System setup |
| [COURSIER_SETUP.md](COURSIER_SETUP.md) | Stage 2: Binary installation | Developers |
| [QUICK_START_PUBLISHING.md](QUICK_START_PUBLISHING.md) | Quick publishing guide | Maintainers |

## Tool & Configuration Guides

| Document | Purpose | Use Case |
|----------|---------|----------|
| [SDKMAN_MAINTENANCE.md](SDKMAN_MAINTENANCE.md) | Manage SDKMan & JVM tools | Post-installation tool management |
| [MANUAL_PUBLISHING.md](MANUAL_PUBLISHING.md) | Publish to Maven Central | Local/manual releases |
| [PUBLISHING.md](PUBLISHING.md) | Complete publishing guide | Full publishing workflow |
| [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) | Pre-release verification | Release management |

## File Structure

```
cumulus.dotfiles/
├── bootstrap.sh                    # Stage 1: Bootstrap installer
├── build.sbt                       # Scala build configuration
├── src/
│   ├── main/scala/cumulus/        # Scala CLI implementation
│   │   ├── Main.scala             # Entry point, command dispatch
│   │   └── dotfiles/              # Feature modules
│   │       ├── install/           # Installation (Stage 3)
│   │       ├── validate/          # Health checks
│   │       ├── theme/             # Theme engine
│   │       ├── sysutils/          # System utilities
│   │       └── ...
│   └── test/scala/cumulus/        # Unit tests
│
├── scripts/
│   ├── maintain-sdkman.sh          # SDKMan tool management
│   └── ...
│
├── Documentation/
│   ├── README.md                   # Project overview
│   ├── INSTALLATION_FLOW.md        # 3-stage installation
│   ├── BOOTSTRAP_SETUP.md          # Stage 1 details
│   ├── COURSIER_SETUP.md           # Stage 2 details
│   ├── MANUAL_PUBLISHING.md        # Local publishing
│   ├── PUBLISHING.md               # Full publishing guide
│   ├── SDKMAN_MAINTENANCE.md       # Tool management
│   ├── RELEASE_CHECKLIST.md        # Release steps
│   ├── QUICK_START_PUBLISHING.md   # Quick publish guide
│   ├── DOCUMENTATION.md            # This file
│   └── project-context.md          # Project context
│
└── Configuration/
    ├── config/sway/               # Sway window manager config
    ├── config/waybar/             # Status bar config
    ├── config/kitty/              # Terminal config
    ├── zsh/                       # ZSH shell config
    └── .github/workflows/         # CI/CD pipelines
```

## Understanding the 3-Stage Flow

### Stage 1: Bootstrap
**Document:** [BOOTSTRAP_SETUP.md](BOOTSTRAP_SETUP.md)

Installs minimal system setup:
- System dependencies (Sway, Waybar, Kitty, etc.)
- Java 21 GraalVM (for native image support)
- Coursier (dependency manager)
- SDKMan (tool manager)

**Script:** `bootstrap.sh`
**Time:** 5-10 minutes

### Stage 2: Coursier
**Document:** [COURSIER_SETUP.md](COURSIER_SETUP.md)

Downloads the cumulus CLI binary:
- Fetches JAR from Maven Central
- Resolves dependencies
- Creates launch script

**Command:** `cs install io.github.petrolal::cumulus:0.1.0`
**Time:** 1-2 minutes

### Stage 3: Interactive Installer
**Document:** [INSTALLATION_FLOW.md](INSTALLATION_FLOW.md)

Scala-based CLI handles full setup:
- Interactive configuration prompts
- Symlink deployment
- Desktop setup
- Health checks

**Command:** `cumulus install`
**Time:** 5-15 minutes
**Location:** `src/main/scala/cumulus/dotfiles/install/DeployInstaller.scala`

## Key Components

### Scala CLI (cumulus)

**Main entry point:** `src/main/scala/cumulus/Main.scala`

**Subcommands:**
- `install` - Full interactive setup (Stage 3)
- `theme` - Desktop theme management
- `healthcheck` - System verification
- `lock` - Screen locker
- `idle` - Auto-lock daemon
- `screenshot` - Screen capture
- `backup/restore` - Configuration snapshots
- `install-*` - Tool-specific installers

### Bootstrap Script (bash)

**File:** `bootstrap.sh`

**Functions:**
- `detect_pkg_mgr()` - Detect package manager
- `install_system_deps()` - Install OS packages
- `install_java()` - Install Java via SDKMan
- `install_coursier()` - Install Coursier

### SDKMan Tool Management

**File:** `scripts/maintain-sdkman.sh`

**Interactive setup:**
```bash
./scripts/maintain-sdkman.sh install
```

**Commands:**
- `check` - Status verification
- `upgrade` - Upgrade SDKMan
- `list` - List installed tools
- `available <tool>` - Show available versions
- `update-*` - Update specific tools
- `update-all` - Update everything

## Publishing Workflow

### Automatic (GitHub Actions)

1. Push version tag: `git tag v0.1.0 && git push origin v0.1.0`
2. GitHub Actions runs CI/CD pipeline
3. Artifacts automatically published to Maven Central

**Pipeline:** `.github/workflows/deploy.yml`

### Manual Publishing

See [MANUAL_PUBLISHING.md](MANUAL_PUBLISHING.md)

```bash
export SONATYPE_USERNAME="..."
export SONATYPE_PASSWORD="..."
export PGP_PASSPHRASE="..."
sbt +publishSigned sonatypeBundleRelease
```

## Development Workflow

### Building

```bash
# Build Scala code
sbt compile

# Run tests
sbt test

# Build native image
sbt nativeImage

# Assemble fat JAR
sbt assembly
```

### Testing

```bash
# Run unit tests
sbt test

# Run specific test
sbt 'testOnly cumulus.InstallSuite'

# Run with coverage
sbt 'clean; coverage; test; coverageReport'
```

### Local Installation

```bash
# Build native image
sbt nativeImage

# Install to ~/.local/bin
mkdir -p ~/.local/bin
cp target/native-image/cumulus ~/.local/bin/

# Test
cumulus --version
```

## Configuration Files

| File | Purpose |
|------|---------|
| `build.sbt` | Scala build configuration |
| `project/plugins.sbt` | sbt plugins |
| `.github/workflows/deploy.yml` | CI/CD pipeline |
| `PKGBUILD` | Arch Linux package |
| `.SRCINFO` | AUR metadata |

## Documentation Best Practices

When updating documentation:

1. **Keep it current** - Update docs when code changes
2. **Link across docs** - Use [MarkdownLinks](files.md) for navigation
3. **Provide examples** - Show command usage with output
4. **Test instructions** - Verify guides work end-to-end
5. **Update index** - Add new docs to this file

## See Also

- [Project Context](project-context.md) - Detailed project background
- [GitHub Repository](https://github.com/petrolal/cumulus.dotfiles)
- [Maven Central](https://search.maven.org/search?q=io.github.petrolal:cumulus)
- [AUR Package](https://aur.archlinux.org/packages/cumulus-dotfiles)

## Quick Links by Task

### "I want to install cumulus"
→ [INSTALLATION_FLOW.md](INSTALLATION_FLOW.md) - 3 commands

### "I'm having installation issues"
→ [BOOTSTRAP_SETUP.md](BOOTSTRAP_SETUP.md#troubleshooting) - Troubleshooting section

### "I want to publish a release"
→ [MANUAL_PUBLISHING.md](MANUAL_PUBLISHING.md) or [QUICK_START_PUBLISHING.md](QUICK_START_PUBLISHING.md)

### "I need to manage JVM tools"
→ [SDKMAN_MAINTENANCE.md](SDKMAN_MAINTENANCE.md)

### "I want to build from source"
→ [README.md](README.md#building-from-source)

### "I'm developing cumulus"
→ This file's "Development Workflow" section

---

**Last Updated:** 2026-08-12
**Status:** Documentation complete for 3-stage installation flow
