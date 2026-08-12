# Epic 8 Context: Theme Template Rendering & Sway IPC Multi-Monitor Autotiling

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Deliver theme palette template rendering (generating Kitty `kitty.conf`, Waybar `style.css`, Wofi `wofi.css`, and Swaylock colors dynamically) and multi-monitor output floating window filtering in the Sway autotiling daemon.

## Stories

- Story 8.1: Color Palette Parser & Template Rendering Engine (`theme`)
- Story 8.2: Multi-Monitor & Floating Window Autotiling Event Loop (`autotiling`)

## Requirements & Constraints

- **Template Rendering**: Parse theme JSON definitions (`catppuccin-mocha`, `nord`, etc.) and render theme configs for Kitty, Waybar, Wofi, and Swaylock via `os-lib`.
- **Multi-Monitor Autotiling**: Calculate window aspect ratios per active output display in Sway, ignoring floating nodes.
- **Zero Reflection Serialization**: Use `uPickle` for reading theme palette JSON files.

## Technical Decisions

- Modules: `cumulus.dotfiles.theme.ThemeEngine`, `cumulus.dotfiles.autotiling.AutotilingDaemon`.
- Template replacement replaces `{{base}}`, `{{text}}`, `{{accent}}` tokens dynamically.
