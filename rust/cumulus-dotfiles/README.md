# cumulus-dotfiles

Rust tooling suite for [cumulus.dotfiles](https://github.com/petrolal/cumulus.dotfiles) — a personal Sway/Wayland desktop (cloud-themed: AWS/Azure/GCP/OCI).

100% of the project's automation, theme engine, installers, system utilities, health checks, and SDD framework are implemented in this pure-Rust library and multi-call binary crate.

## Installation

```sh
cargo install --path .
```

This compiles and installs the `cumulus` umbrella binary and all 23 multi-call symlinks/aliases (`cumulus-install`, `cumulus-theme`, `cumulus-validate`, `cumulus-sdd`, etc.) into `~/.cargo/bin`.

## Commands & Multi-Call Binaries

Each command works both as a direct binary (`cumulus-<name>`) and as an umbrella subcommand (`cumulus <name>`):

```sh
cumulus theme set aws --rotate    # or: cumulus-theme set aws --rotate
cumulus install --links-only     # or: cumulus-install --links-only
cumulus sdd verify               # or: cumulus-sdd verify
```

| Command | Subcommand | Purpose |
|---|---|---|
| `cumulus-install` | `cumulus install` | Deploy desktop configs via symlinks, install system packages, fonts, & toolchains. |
| `cumulus-theme` | `cumulus theme` | Theme engine for cloud flavors (AWS, Azure, GCP, OCI) & background modes (flat, wallpaper, rotate). |
| `cumulus-validate` | `cumulus validate` | Health check verifying symlinks, sway configs, tools, & runtime environment. |
| `cumulus-backup` | `cumulus backup` | Create timestamped tarball snapshots of managed config directories. |
| `cumulus-restore` | `cumulus restore` | Restore a saved backup snapshot with automatic safety pre-restoration backups. |
| `cumulus-update` | `cumulus update` | Pull latest git changes and re-run installation in-process. |
| `cumulus-sdd` | `cumulus sdd` | Spec-driven development framework CLI (`init`, `new`, `verify`). |
| `cumulus-autotiling` | `cumulus autotiling` | Sway IPC daemon for Fibonacci window autotiling. |
| `cumulus-lock` | `cumulus lock` | Cloud-styled swaylock wrapper. |
| `cumulus-idle` | `cumulus idle` | Swayidle daemon managing idle timeouts, locking, and system suspend. |
| `cumulus-screenshot` | `cumulus screenshot` | Screen capture tool via `grim` and `slurp` (full, region, window). |
| `cumulus-theme-picker` | `cumulus theme-picker` | Wofi GUI picker for themes and background modes. |
| `cumulus-whichkey` | `cumulus whichkey` | Wofi live keybinding cheatsheet parsed directly from Sway config. |
| `cumulus-install-*` | `cumulus install-*` | Modular toolchain installers (`apps`, `browser`, `devops`, `fonts`, `nvim`, `nvim-deps`, `sdkman`, `zsh`). |

## Design Principles

- **std-only / low dependencies** — builds cleanly offline on fresh Linux installations.
- **Multi-call dispatch** — single binary architecture (`dispatch()`) checks `argv[0]` or the first positional argument.
- **Data safety & idempotency** — existing real files are backed up to `~/.cumulus_backup/<ts>/` before linking; re-running skips already valid symlinks.
- **Atomic state writes** — theme state (`~/.config/cumulus/theme/state`) is updated atomically.

## Development & Testing

```sh
cargo test                  # 47 unit & integration tests
cargo clippy --all-targets  # lints
cargo fmt                   # code formatting
```

## License

MIT

