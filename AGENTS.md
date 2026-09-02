<!-- bmad:context -->
<!-- Verified 2026-08-25 against 996b6dc. Managed by bmad-project-context; edits inside this block are replaced on refresh. Keep anything you want preserved outside the markers. -->

## polyomino.dotfiles

Polyomino: A bespoke, puzzle-geometric Sway dotfiles suite inspired by ML4W, combinatorics, and Portuguese navigation lore. Configuration files are managed as symlinks.

## Policy

- Never commit secrets or API keys; use `~/.polyomino.local.zsh` for local environment variables instead.

## Where things are

- Core Scala CLI engine: `src/`
- Shell configurations: `zsh/` (specifically `zsh/zsh_config/`)
- Desktop/UI configurations: `config/` (Sway, Wofi, Waybar, Kitty)
- System package bootstrap: `bootstrap.sh`

## Conventions that differ from defaults

- This repository manages files via symlinks into `$HOME` (`polyomino install`). When editing configurations, edit them in this repository rather than directly in `$HOME`.

<!-- /bmad:context -->

## Polyomino Visual Identity Constraints

> **Scope Notice:** This project is strictly a user-level **Sway dotfiles configuration suite** (Waybar, Sway window styling, Fastfetch, Wofi/Rofi, Dunst). It is **NOT** a Linux distribution or operating system.
> **Preservation Guardrail:** The underlying Linux OS, system packages, display manager, shell runtimes, JVM/Java/Kotlin developer tools, and Sway keybindings must remain completely untouched during all visual refactors.

### Agent Verification Rule
Any agent implementing a story must verify visual layout parity against the approved ML4W-style mockup without altering underlying execution scripts or system configs.
