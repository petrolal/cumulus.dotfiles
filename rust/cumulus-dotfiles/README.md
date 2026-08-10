# cumulus-dotfiles

Rust tooling for [cumulus.dotfiles](https://github.com/petrolal/cumulus.dotfiles)
— a personal Sway/Wayland desktop (cloud-themed: AWS/Azure/GCP/OCI). This crate
is the ongoing Rust rewrite of the project's shell scripts: one library plus a
suite of `cumulus-*` commands.

## Install

```sh
cargo install cumulus-dotfiles
```

This installs the `cumulus` umbrella command and every `cumulus-*` alias into
`~/.cargo/bin` (ensure it is on your `PATH`).

## Commands

Each command works both as an alias and as an umbrella subcommand:

```sh
cumulus-theme list          # or: cumulus theme list
```

| Command         | Purpose                                                        |
| --------------- | -------------------------------------------------------------- |
| `cumulus-theme` | Select a flavor + background mode (flat/wallpaper/rotate) live. |

More commands (installers, validate, backup/restore, screenshot, lock, idle,
runtime-refresh, autotiling, …) are being ported from the original shell
scripts; see the repository's migration roadmap.

## Design

- **std-only** — no third-party dependencies, so it builds offline on a fresh
  machine.
- **Multi-call binaries** — all logic lives in the `cumulus_dotfiles` library;
  each installed binary dispatches on its own `argv[0]` name.
- **Result-based errors** — fallible operations return `Result`; the process
  prints one error and exits non-zero (no scattered `exit()` calls).
- **Behaviour parity** — the theme engine is byte-for-byte compatible with the
  original `scripts/theme.sh`, including the generated config files, the
  `~/.config/cumulus/theme/state` format, error messages, and locale-aware
  wallpaper ordering.

## Repository layout

The command needs to find the dotfiles checkout (palettes, templates,
wallpapers). It uses `CUMULUS_DOTFILES_DIR` if set, otherwise walks up from the
executable to the directory containing `themes/palettes`.

## Development

```sh
cargo test        # unit + integration tests (mirror the old tests/*.sh)
cargo clippy --all-targets
cargo fmt
```

## License

MIT
