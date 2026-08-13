# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**cumulus.dotfiles** is a high-performance desktop environment tooling suite for Sway/Wayland Linux. It's a multi-call native binary (compiled with GraalVM) that handles:
- Dynamic window autotiling (Fibonacci spiral layout)
- Desktop theme switching across application surfaces (AWS, Azure, GCP, OCI themes)
- System provisioning and dotfile management
- Screen locking, idle daemon management, screenshots
- System health validation and configuration snapshots

All subcommands compile into a single native executable that's distributed via Maven Central and GitHub Releases. See `docs/project-context.md` for detailed architecture, design decisions, and performance targets.

## Build & Development Commands

### Prerequisites
- **Java 21+** and **sbt 1.10.2+**
- Install via: `bash bootstrap.sh` (sets up Java + Coursier)

### Common Tasks

```bash
# Compile and run unit tests
sbt test

# Run a single test suite
sbt 'testOnly cumulus.AutotilingSuite'

# Compile to native image (~5 min, requires GraalVM setup)
sbt nativeImage

# Run native binary from source
./target/native-image/cumulus --help
./target/native-image/cumulus install --help

# Create fat JAR for Maven Central upload (for testing)
sbt assembly

# Clean build artifacts
sbt clean

# Check compilation without running
sbt compile

# Format code (if formatter is configured)
sbt scalafmt
```

### Development Workflow

1. **Edit Scala code** → `sbt compile` to catch type errors immediately
2. **Add tests** → Place in `src/test/scala/cumulus/<ModuleName>Suite.scala`, follow munit patterns
3. **Test subcommand** → `sbt 'testOnly cumulus.MainSuite'` to test command dispatch
4. **Build native binary** → `sbt nativeImage` (slower but final distribution format)
5. **Manual testing** → `./target/native-image/cumulus <command>` to test behavior

## Code Architecture

### Module Structure

The codebase is organized by feature/concern:

```
src/main/scala/cumulus/
├── Main.scala                          # Entry point, command dispatch router
└── dotfiles/
    ├── context/Context.scala           # XDG path discovery, environment setup
    ├── error/CumulusError.scala        # Error types (Either-based)
    ├── autotiling/AutotilingDaemon.scala
    ├── install/                        # Symlink creation, manifest, tool installers
    ├── theme/                          # Theme engine, color palettes
    ├── refresh/                        # App reload signals (waybar, kitty, etc.)
    ├── sysutils/                       # Lock, idle, screenshot helpers
    ├── pickers/WofiPickers.scala       # GUI launchers (wofi)
    ├── maintenance/                    # Backup/restore, git pull
    ├── sdd/SpecDrivenDev.scala         # AI context generation
    └── validate/Validator.scala        # Health check
```

### Key Architectural Patterns

1. **Functional Error Handling**: All modules use `Either[CumulusError, T]` for error propagation (no exceptions at boundaries)
2. **Context-Driven**: `Context` case class holds XDG paths, env vars, Sway IPC socket—discovered once at startup and threaded through all calls
3. **Multi-Call Binary**: Single executable (`cumulus`) with command dispatch via `argv[0]` inspection; symlinks in `~/.local/bin/cumulus-<subcommand>` point to it
4. **Non-Reflective Design**: Uses `uPickle` macros (compile-time) and `mainargs` macros for JSON serialization and CLI parsing—zero runtime reflection, fully GraalVM native-image compatible
5. **Streamed I/O**: Process execution streams output directly (via `os.proc(...).stream()`) to avoid buffering large outputs

### Dependencies

- **os-lib**: File I/O, process execution, path manipulation
- **uPickle**: JSON serialization (zero-reflection compile-time macros)
- **mainargs**: CLI argument parsing (type-safe, macro-based)
- **munit**: Unit testing framework

## Testing

Tests use **munit** and follow convention-based discovery:

```bash
# Run all tests
sbt test

# Run tests for a specific module (e.g., autotiling calculations)
sbt 'testOnly cumulus.AutotilingSuite'

# Run with verbose output
sbt test -- --verbose
```

Test files are in `src/test/scala/cumulus/` with names ending in `Suite.scala`. Each module has a corresponding test suite (AutotilingSuite, ThemeSuite, InstallSuite, etc.).

## Common Development Patterns

### Adding a New Subcommand

1. Create `src/main/scala/cumulus/dotfiles/<module>/<Module>.scala`
2. Implement main execution logic returning `Either[CumulusError, Unit]`
3. Add case in `Main.scala` dispatch logic to route to your module
4. Create `src/test/scala/cumulus/<Module>Suite.scala` with unit tests
5. Test via: `sbt test` then `sbt nativeImage` to verify native compilation

### Adding a Test

Create a test file following this pattern:

```scala
class YourModuleSuite extends munit.FunSuite {
  test("description of what should happen") {
    val result = YourModule.someFunction()
    assertEquals(result, expectedValue)
  }
}
```

Run with: `sbt 'testOnly cumulus.YourModuleSuite'`

### Error Handling

Define error types in `error/CumulusError.scala` as sealed traits:

```scala
sealed trait CumulusError
case class CommandError(msg: String) extends CumulusError
```

Return via `Either`:

```scala
def myFunction(): Either[CumulusError, String] = {
  if (condition) Right("success")
  else Left(CommandError("reason"))
}
```

Main entry point catches and formats errors with ANSI colors.

### Working with Context

Always accept `Context` as a parameter for access to paths and environment:

```scala
def myFunction(ctx: Context): Either[CumulusError, Unit] = {
  val configPath = ctx.configDir / "sway" / "config"
  // Use ctx.homePath, ctx.xdgDataHome, ctx.swaySocket, etc.
  Right(())
}
```

Tests can inject a mock context via environment variables (see Context.scala for how XDG vars override defaults).

## Publishing & Distribution

### Maven Central
- Coordinates: `io.github.petrolal:cumulus:0.1.0` (edit version in `build.sbt`)
- Published via Sonatype Central Portal (`s01.oss.sonatype.org`)
- Requires PGP signing (GitHub Actions CI handles this automatically)

### GitHub Actions CI/CD
- Triggered on version tags (e.g., `git tag v0.1.0 && git push origin v0.1.0`)
- Builds native image, publishes to Maven Central, creates GitHub Release with binary attached
- See `.github/workflows/deploy.yml`

### Local Distribution Testing
```bash
sbt assembly                    # Creates fat JAR
sbt nativeImage                 # Creates native binary
```

## Important Notes

### GraalVM Native Image Constraints

The codebase is designed to be 100% GraalVM native-image compatible:

- **No reflection**: All JSON parsing uses `uPickle` macros (compile-time code generation)
- **No `reflect-config.json` needed**: Macro-based approach avoids reflection configuration burden
- **GraalVM flags** (in `build.sbt`):
  - `--no-fallback`: Fail at build time if reflection can't be resolved
  - `-H:+ReportExceptionStackTraces`: Include stack trace symbols
  - `--enable-preview`: Enable preview features

If adding new dependencies, prefer libraries with zero-reflection support (check GitHub for "graalvm native-image" compatibility).

### Performance Targets

- **Startup latency**: 15–50 ms (native image, no JVM)
- **Memory RSS**: <60 MB peak
- **Binary size**: 40–60 MB

Avoid patterns that increase startup time (lazy static initialization, class scanning) or memory usage (large in-memory buffers, deep object graphs).

### Sway/Wayland Integration

Modules that interact with Sway use IPC via `swaymsg` command (routed through `os.proc(...)`). The Sway socket path is discovered via `Context.swaySocket` (read from `SWAYSOCK` env var or derived from XDG_RUNTIME_DIR).

For desktop integration updates (Waybar, Kitty, GTK settings), see `refresh/RefreshEngine.scala` for how signals are sent to running apps.

## Documentation References

- **Architecture & Design**: See `docs/project-context.md` for detailed module breakdown, design decisions, performance optimization targets
- **Installation Flow**: `docs/INSTALLATION_FLOW.md` — how the 3-stage installer works
- **Publishing**: `docs/PUBLISHING.md` — Maven Central and AUR package details
- **README**: `README.md` — user-facing commands, keybindings, quick-start instructions

## Debugging

### View Compiled Assembly
```bash
sbt assembly
unzip -l target/scala-3.5.2/cumulus-0.1.0-assembly.jar | grep cumulus
```

### Check Native Image Build
```bash
sbt nativeImage
# Check binary size & symbols
ls -lh target/native-image/cumulus
strings target/native-image/cumulus | head -20
```

### Test with Environment Overrides
Set XDG env vars to test path discovery without affecting system:

```bash
export XDG_CONFIG_HOME=/tmp/test-config
export XDG_DATA_HOME=/tmp/test-data
sbt 'testOnly cumulus.MainSuite'
```

### Trace Process Execution
`os-lib` commands are logged at debug level. Some modules print to stderr. Check implementation for `println` or logging calls.
