# Epic 3 Context: Live Theme Engine, Color Sync & Wofi Pickers

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Deliver live desktop theme switching (`theme`), app color scheme reloads (`runtime-refresh`, `os-colorscheme`, `rgb-theme`), and interactive Wofi GUI launchers (`theme-picker`, `whichkey`).

## Stories

- Story 3.1: Live Desktop Theme Application Engine (`theme`)
- Story 3.2: Runtime App Refresh & Color Scheme Synchronization (`runtime-refresh`, `os-colorscheme`, `rgb-theme`)
- Story 3.3: Interactive Wofi GUI Theme & Cheatsheet Pickers (`theme-picker`, `whichkey`)

## Requirements & Constraints

- **Live Reload Signals**: Theme updates trigger live signals across desktop components (Sway `swaymsg reload`, Kitty `kill -USR1`, GNOME `gsettings set org.gnome.desktop.interface color-scheme`).
- **Wofi Interactivity**: `theme-picker` and `whichkey` stream menu choices to `wofi -dmenu`, executing theme changes directly upon selection.
- **Zero Reflection Config Parsing**: Parse theme definitions using `uPickle` static derives (`ReadWriter`) without JVM reflection.

## Technical Decisions

- Modules: `cumulus.dotfiles.theme.ThemeEngine`, `cumulus.dotfiles.refresh.RefreshEngine`, `cumulus.dotfiles.pickers.WofiPickers`.
- Use `os-lib` (`os.proc`, `os.symlink`, `os.list`) for theme file switching and process signaling.
