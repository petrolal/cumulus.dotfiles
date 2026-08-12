---
title: 'Epic 8: Theme Template Rendering & Sway IPC Multi-Monitor Autotiling'
type: 'feature'
created: '2026-08-12'
status: 'done'
baseline_commit: '4bffa6d'
review_loop_iteration: 0
context:
  - _bmad-output/implementation-artifacts/epic-8-context.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Theme switching needs to dynamically render Kitty, Waybar, and Wofi config files from palette definitions, and the autotiling daemon needs to support multi-monitor outputs and filter floating windows.

**Approach:** Expand `ThemeEngine` with a template rendering engine using `uPickle` color definitions, and expand `AutotilingDaemon` to traverse Sway multi-monitor trees.

## Boundaries & Constraints

**Always:** Write generated theme configs to `~/.config/kitty/theme.conf`, `~/.config/waybar/theme.css`, `~/.config/wofi/theme.css`.

**Ask First:** Changing default theme color token names.

**Never:** Apply autotiling split logic to floating window nodes.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Theme Render | `cumulus theme nord` | Renders `kitty/theme.conf`, `waybar/theme.css`, `wofi/theme.css` | Uses fallback colors if palette missing |
| Multi-Monitor Autotiling | 2 active monitors | Calculates aspect ratio for focused tiled window per output | Ignores floating windows |

</frozen-after-approval>

## Code Map

- `src/main/scala/cumulus/dotfiles/theme/Palette.scala` -- Theme color palette model and default themes.
- `src/main/scala/cumulus/dotfiles/theme/ThemeEngine.scala` -- Template rendering and config generation.
- `src/main/scala/cumulus/dotfiles/autotiling/AutotilingDaemon.scala` -- Multi-monitor tree traversal.

## Tasks & Acceptance

**Execution:**
- [x] `src/main/scala/cumulus/dotfiles/theme/Palette.scala` -- Create `Palette` model and default palettes -- Theme palette definitions.
- [x] `src/main/scala/cumulus/dotfiles/theme/ThemeEngine.scala` -- Implement Kitty, Waybar, Wofi template rendering -- Template rendering engine.
- [x] `src/main/scala/cumulus/dotfiles/autotiling/AutotilingDaemon.scala` -- Implement multi-monitor output traversal and floating node filter -- Multi-monitor autotiling logic.

**Acceptance Criteria:**
- Given a theme flavor, when executing `cumulus theme <flavor>`, then Kitty, Waybar, and Wofi theme files are rendered and updated.
- Given a multi-monitor Sway session, when tiling windows, then autotiling calculates window split per monitor output.

## Verification

**Commands:**
- `sbt compile` -- expected: SUCCESS_CRITERIA

## Suggested Review Order

**Theme Template Rendering & Sway IPC Multi-Monitor Autotiling**

- Theme palette definitions (Catppuccin Mocha, Nord, TokyoNight)
  [`Palette.scala:1`](../../src/main/scala/cumulus/dotfiles/theme/Palette.scala#L1)

- Kitty, Waybar, and Wofi template rendering engine
  [`ThemeEngine.scala:1`](../../src/main/scala/cumulus/dotfiles/theme/ThemeEngine.scala#L1)

- Multi-monitor Sway output tree traversal and floating window filtering
  [`AutotilingDaemon.scala:1`](../../src/main/scala/cumulus/dotfiles/autotiling/AutotilingDaemon.scala#L1)

