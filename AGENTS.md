<!-- bmad:context -->
<!-- Verified 2026-08-13 against 22ed675. Managed by bmad-project-context; edits inside this block are replaced on refresh. Keep anything you want preserved outside the markers. -->

## cumulus.dotfiles

High-performance desktop environment tooling suite for Sway/Wayland (Scala 3 + GraalVM native image). Single multi-call binary compiled to native, distributed via Maven Central, AUR, and GitHub Releases. Architecture, detailed module breakdown, and publishing flow in `docs/project-context.md`, `docs/INSTALLATION_FLOW.md`, `docs/PUBLISHING.md`.

## Where things are

- **Developer guide**: `CLAUDE.md` — build commands, testing patterns, workflow, examples, debugging
- **Architecture & module guide**: `docs/project-context.md`
- **Installation flow (3-stage bootstrap)**: `docs/INSTALLATION_FLOW.md`
- **Publishing to Maven Central & AUR**: `docs/PUBLISHING.md`
- **SDKMan / build toolchain maintenance**: `docs/SDKMAN_MAINTENANCE.md`

## Conventions that differ from defaults

- **Error handling**: All public functions return `Either[CumulusError, T]`, never throw exceptions at module boundaries. Define new error types in `error/CumulusError.scala` as sealed traits.
- **JSON serialization**: Use `uPickle` derive macros (compile-time); zero reflection, 100% GraalVM native-image safe. No `reflect-config.json` needed.
- **CLI parsing**: Use `mainargs` macros for type-safe argument parsing; compile-time code generation, no reflection.
- **Process I/O**: Stream via `os.proc(...).stream()` to avoid buffering large outputs; use `os-lib` for all file I/O and path manipulation.
- **Context threading**: All functions accept `Context` parameter for access to XDG paths, environment, Sway socket. Discover once at startup, thread through calls.
- **Testing patterns**: Test files in `src/test/scala/cumulus/` named `*Suite.scala`; use munit framework. Each module has a corresponding test suite (e.g., `AutotilingSuite` for autotiling).

## Known pitfalls

- **GraalVM native image build times**: `sbt nativeImage` takes ~5 minutes on CI. Avoid frequent native builds during iteration—use `sbt compile` and `sbt test` first.
- **Sonatype credentials**: Publish flow requires `PGP_PASSPHRASE`, `PGP_SECRET`, `SONATYPE_USERNAME`, `SONATYPE_PASSWORD` secrets in GitHub Actions. These are pre-configured but sensitive—never commit or echo them in CI logs. Recent fix: see commit 22ed675 for credential setup details.
- **Reflection incompatible with GraalVM**: Adding dependencies that use reflection (e.g., Play Framework, Scala Reflect) requires `reflect-config.json` and breaks `--no-fallback` native image flag. Prefer zero-reflection libraries; check GitHub issues for "graalvm native-image" compatibility before adding deps.

<!-- /bmad:context -->
