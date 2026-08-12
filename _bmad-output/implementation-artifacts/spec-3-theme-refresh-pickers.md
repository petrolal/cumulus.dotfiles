---
title: 'Epic 3: Live Theme Engine, Color Sync & Wofi Pickers'
type: 'feature'
created: '2026-08-12'
status: 'done'
baseline_commit: 'f93bd14'
review_loop_iteration: 0
context:
  - _bmad-output/implementation-artifacts/epic-3-context.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Theme switching, GNOME GTK color synchronization, hardware RGB updates, and Wofi GUI pickers are missing in the Scala codebase.

**Approach:** Implement `ThemeEngine`, `RefreshEngine`, and `WofiPickers` using `os-lib` for filesystem symlinking, subprocess signaling, and `uPickle` JSON config parsing.

## Boundaries & Constraints

**Always:** Use `os-lib` (`os.symlink`, `os.proc`) for config updates and signaling (`swaymsg reload`, `gsettings`, `wofi -dmenu`).

**Ask First:** Modifying theme directory locations (`~/.config/sway/themes`).

**Never:** Block main thread on interactive Wofi subprocesses.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Theme Apply | `cumulus theme catppuccin-mocha` | Updates config symlinks and reloads Sway/Kitty/Waybar | Reports non-existent theme flavor |
| GTK Dark Sync | `cumulus os-colorscheme` | Runs `gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'` | Gracefully handles gsettings missing |
| Wofi Theme Picker | `cumulus theme-picker` | Opens Wofi dmenu listing themes and applies choice | Exits cleanly on ESC / cancel |

</frozen-after-approval>

## Code Map

- `src/main/scala/cumulus/dotfiles/theme/ThemeEngine.scala` -- Desktop theme & wallpaper switcher engine.
- `src/main/scala/cumulus/dotfiles/refresh/RefreshEngine.scala` -- Runtime reloads, GTK color sync, and OpenRGB.
- `src/main/scala/cumulus/dotfiles/pickers/WofiPickers.scala` -- Wofi GUI theme picker and keybindings cheatsheet.
- `src/main/scala/cumulus/Main.scala` -- Connects theme, refresh, and picker subcommands.

## Tasks & Acceptance

**Execution:**
- [x] `src/main/scala/cumulus/dotfiles/theme/ThemeEngine.scala` -- Implement `ThemeEngine.run(ctx, args)` -- Desktop theme switcher.
- [x] `src/main/scala/cumulus/dotfiles/refresh/RefreshEngine.scala` -- Implement `RefreshEngine.runRefresh`, `runOsColorscheme`, `runRgbTheme` -- Live app color reloads.
- [x] `src/main/scala/cumulus/dotfiles/pickers/WofiPickers.scala` -- Implement `WofiPickers.runThemePicker`, `runWhichkey` -- Interactive Wofi GUI launchers.
- [x] `src/main/scala/cumulus/Main.scala` -- Wire theme, refresh, and picker subcommands to handlers -- Dispatch integration.

**Acceptance Criteria:**
- Given a valid theme name, when executing `cumulus theme <flavor>`, then config symlinks are updated and reload signals sent.
- Given `cumulus theme-picker`, when executed, then Wofi launcher opens listing themes and applies the chosen entry.

## Verification

**Commands:**
- `sbt compile` -- expected: SUCCESS_CRITERIA

## Suggested Review Order

**Live Theme Engine, Color Sync & Wofi Pickers**

- Theme application engine and wallpaper management
  [`ThemeEngine.scala:1`](../../src/main/scala/cumulus/dotfiles/theme/ThemeEngine.scala#L1)

- Runtime app reloads, GTK color sync, and OpenRGB
  [`RefreshEngine.scala:1`](../../src/main/scala/cumulus/dotfiles/refresh/RefreshEngine.scala#L1)

- Interactive Wofi GUI theme picker and keybindings cheatsheet
  [`WofiPickers.scala:1`](../../src/main/scala/cumulus/dotfiles/pickers/WofiPickers.scala#L1)

- Main CLI dispatcher wiring for theme/refresh/pickers
  [`Main.scala:37`](../../src/main/scala/cumulus/Main.scala#L37)

