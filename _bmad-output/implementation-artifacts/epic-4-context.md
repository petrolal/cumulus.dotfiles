# Epic 4 Context: Sway Fibonacci Autotiling Daemon

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Deliver the dynamic window autotiling daemon (`cumulus autotiling`) for the Sway window manager, connecting to the Sway IPC socket and automatically setting window split orientations into a Fibonacci spiral.

## Stories

- Story 4.1: Sway IPC Unix Domain Socket Event Listener (`autotiling`)

## Requirements & Constraints

- **Sway IPC Connection**: Connect to the Unix domain socket specified by `SWAYSOCK`.
- **Low Overhead**: Handle window focus/creation events efficiently without spawning excess processes or leaking memory.
- **Fibonacci Spiral Split Logic**: Check focused window dimensions (width vs height); if width > height, issue `swaymsg split h`, otherwise issue `swaymsg split v`.

## Technical Decisions

- Module: `cumulus.dotfiles.autotiling.AutotilingDaemon`.
- Use POSIX socket or `os.proc` streaming for Sway IPC split commands.
