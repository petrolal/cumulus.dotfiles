//! Session utilities that wrap Sway/Wayland tools: the themed swaylock wrapper
//! (`lock.sh`), the swayidle daemon (`idle.sh`), and the grim/slurp screenshot
//! helper (`screenshot.sh`).

use crate::context::Context;
use crate::error::{Error, Result};
use crate::theme::palette::Palette;
use crate::theme::state::State;
use crate::util;
use std::io::Write;
use std::os::unix::process::CommandExt;
use std::process::{Command, Stdio};

fn strip_hash(s: &str) -> String {
    s.strip_prefix('#').unwrap_or(s).to_string()
}

/// `cumulus-lock` — swaylock styled to follow the active theme. Execs swaylock.
pub fn run_lock(ctx: &Context) -> Result<()> {
    let state = State::load(ctx);
    let mut flavor = state.flavor;
    if flavor.is_empty() {
        flavor = "oci".to_string();
    }
    let palette_path = ctx.palettes_dir().join(format!("{flavor}.sh"));
    let palette = if palette_path.is_file() {
        Palette::load(ctx, &flavor)
    } else {
        Palette::load(ctx, "oci")
    };
    let base = strip_hash(palette.get("BASE"));
    let blue = strip_hash(palette.get("BLUE"));
    let text = strip_hash(palette.get("TEXT"));
    let green = strip_hash(palette.get("GREEN"));

    let err = Command::new("swaylock")
        .args([
            "--color",
            &base,
            "--inside-color",
            &base,
            "--ring-color",
            &blue,
            "--line-color",
            &base,
            "--text-color",
            &text,
            "--inside-ver-color",
            &blue,
            "--ring-ver-color",
            &blue,
            "--key-hl-color",
            &green,
            "--separator-color",
            &base,
            "--font",
            "JetBrainsMono Nerd Font",
            "--indicator-radius",
            "100",
            "--indicator-thickness",
            "10",
        ])
        .exec();
    Err(Error::new(format!("failed to exec swaylock: {err}")))
}

/// Resolve a sibling `cumulus-<name>` binary next to the running executable so
/// the daemon can invoke it whether installed or run from the build tree.
fn sibling_command(name: &str) -> String {
    if let Ok(exe) = std::env::current_exe() {
        if let Some(dir) = exe.parent() {
            let candidate = dir.join(name);
            if candidate.exists() {
                return candidate.to_string_lossy().into_owned();
            }
        }
    }
    name.to_string()
}

/// `cumulus-idle` — swayidle daemon (auto-lock, dpms, suspend). Execs swayidle.
pub fn run_idle(_ctx: &Context) -> Result<()> {
    let lock_cmd = sibling_command("cumulus-lock");
    let err = Command::new("swayidle")
        .args([
            "-w",
            "timeout",
            "300",
            &lock_cmd,
            "timeout",
            "600",
            "swaymsg \"output * dpms off\"",
            "resume",
            "swaymsg \"output * dpms on\"",
            "timeout",
            "900",
            "systemctl suspend",
            "before-sleep",
            &lock_cmd,
        ])
        .exec();
    Err(Error::new(format!("failed to exec swayidle: {err}")))
}

fn notify(msg: &str) {
    if util::command_exists("notify-send") {
        let _ = Command::new("notify-send")
            .args(["Screenshot", msg])
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();
    }
}

/// Capture the focused window geometry via `swaymsg -t get_tree | jq ...`.
fn focused_window_geometry() -> Option<String> {
    let tree = Command::new("swaymsg")
        .args(["-t", "get_tree"])
        .stderr(Stdio::null())
        .output()
        .ok()?;
    if !tree.status.success() {
        return None;
    }
    let mut jq = Command::new("jq")
        .args([
            "-r",
            r#".. | select(.focused? == true) | .rect | "\(.x),\(.y) \(.width)x\(.height)""#,
        ])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .ok()?;
    jq.stdin.take()?.write_all(&tree.stdout).ok()?;
    let out = jq.wait_with_output().ok()?;
    let geom = String::from_utf8_lossy(&out.stdout).trim().to_string();
    (!geom.is_empty()).then_some(geom)
}

/// `cumulus-screenshot [full|region|window]` — grim/slurp screenshot helper.
pub fn run_screenshot(ctx: &Context, args: &[String]) -> Result<()> {
    let mode = args.first().map(String::as_str).unwrap_or("region");
    let dir = ctx.home.join("Pictures/Screenshots");
    std::fs::create_dir_all(&dir)?;
    let stamp = timestamp();
    let file = dir.join(format!("{stamp}.png"));

    match mode {
        "full" => {
            grim(&[file.to_string_lossy().as_ref()])?;
        }
        "region" => {
            let geom = Command::new("slurp").output();
            let geom = match geom {
                Ok(o) if o.status.success() => {
                    String::from_utf8_lossy(&o.stdout).trim().to_string()
                }
                _ => {
                    notify("Cancelled");
                    return Ok(());
                }
            };
            grim(&["-g", &geom, file.to_string_lossy().as_ref()])?;
        }
        "window" => {
            let Some(geom) = focused_window_geometry() else {
                notify("No focused window found");
                return Err(Error::with_code("", 1));
            };
            grim(&["-g", &geom, file.to_string_lossy().as_ref()])?;
        }
        _ => {
            eprintln!("Usage: cumulus-screenshot {{full|region|window}}");
            return Err(Error::with_code("", 1));
        }
    }

    // Copy the saved image to the clipboard, then notify.
    if let Ok(bytes) = std::fs::read(&file) {
        if let Ok(mut child) = Command::new("wl-copy")
            .stdin(Stdio::piped())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .spawn()
        {
            if let Some(mut stdin) = child.stdin.take() {
                let _ = stdin.write_all(&bytes);
            }
            let _ = child.wait();
        }
    }
    notify(&format!(
        "Saved to {} (copied to clipboard)",
        file.display()
    ));
    Ok(())
}

fn grim(args: &[&str]) -> Result<()> {
    let status = Command::new("grim").args(args).status()?;
    if status.success() {
        Ok(())
    } else {
        Err(Error::with_code("grim failed", 1))
    }
}

/// `date +%Y-%m-%d_%H-%M-%S` in local time, via the `date` command for parity.
fn timestamp() -> String {
    Command::new("date")
        .arg("+%Y-%m-%d_%H-%M-%S")
        .output()
        .ok()
        .filter(|o| o.status.success())
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_default()
}
