# Epic 2 Context: Core System Context, Validation & Desktop Helpers

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Deliver system-level desktop helper tools and diagnostic utilities: system health validation (`validate`), AI development context generation (`sdd`), styled screen locking (`lock`), auto-idle daemon management (`idle`), and screen capture (`screenshot`).

## Stories

- Story 2.1: System Context Discovery & Environment Resolution
- Story 2.2: System Validation & Read-Only Health Check (`validate`)
- Story 2.3: Spec-Driven Development Context Generator (`sdd`)
- Story 2.4: System Lock Screen, Auto-Idle & Screenshot Helpers (`lock`, `idle`, `screenshot`)

## Requirements & Constraints

- **Read-Only Validation**: `validate` checks binary executables (`sway`, `waybar`, `kitty`, `wofi`, `swaylock`, `grim`, `slurp`), configuration paths, and fonts without modifying system state.
- **Subprocess Stream I/O**: Use `os.proc` streaming for launching `swaylock`, `swayidle`, `grim`, and `slurp` to maintain zero heap buffer overhead.
- **Formatted CLI Output**: Print green `[OK]` badges for present components and red `[FAIL]` badges for missing required dependencies.

## Technical Decisions

- Use `os-lib` (`os.proc`, `os.exists`, `os.list`) for system binary lookup and file inspection.
- Screen locking formats `swaylock` flags dynamically based on active theme colors in `~/.config/sway/colors`.
