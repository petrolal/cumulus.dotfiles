//! `cumulus-theme-picker` and `cumulus-whichkey` — the two wofi front-ends
//! that live in `config/sway/scripts/`. Ports `theme-picker.sh` and
//! `whichkey.sh`.
//!
//! Both are pure UI layers: theme-picker drives the in-process `theme` command
//! (no logic duplicated here), and whichkey renders a read-only cheatsheet of
//! the live sway keybindings. External tools (`wofi`, `swaymsg`, `jq`,
//! `notify-send`) are invoked exactly as the shell did.

use crate::context::Context;
use crate::error::Result;
use crate::install::sh_capture;
use crate::theme;
use crate::theme::palette::Palette;
use crate::theme::state::State;
use crate::theme::wallpaper;
use crate::util;
use std::io::Write;
use std::process::{Command, Stdio};

// ── shared helpers ──────────────────────────────────────────────────────

/// `notify-send "Theme" "<msg>"` when available; otherwise a no-op.
fn notify(msg: &str) {
    if util::command_exists("notify-send") {
        let _ = Command::new("notify-send").args(["Theme", msg]).status();
    }
}

/// The wofi `pick` helper: feed newline-separated options on stdin, return the
/// selected line (trailing newline stripped). Empty string means "cancelled".
fn pick(prompt: &str, options: &str) -> String {
    let mut child = match Command::new("wofi")
        .args([
            "--show",
            "dmenu",
            "--prompt",
            prompt,
            "--width",
            "500",
            "--height",
            "400",
            "--lines",
            "8",
            "--insensitive",
        ])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
    {
        Ok(c) => c,
        Err(_) => return String::new(),
    };
    if let Some(mut stdin) = child.stdin.take() {
        let _ = stdin.write_all(options.as_bytes());
    }
    let out = match child.wait_with_output() {
        Ok(o) => o,
        Err(_) => return String::new(),
    };
    String::from_utf8_lossy(&out.stdout)
        .trim_end_matches('\n')
        .to_string()
}

fn source_label(source: &str) -> &'static str {
    match source {
        "user" => "custom wallpaper (preserved)",
        "theme-default" => "theme default wallpaper",
        "rotate" => "rotating wallpapers",
        "flat" => "flat color",
        _ => "legacy/unknown wallpaper source",
    }
}

// ── theme-picker ────────────────────────────────────────────────────────

pub fn run_theme_picker(ctx: &Context, _args: &[String]) -> Result<()> {
    let state = State::load(ctx);
    let current_flavor = state.flavor.clone();
    let current_mode = if state.mode.is_empty() {
        "flat".to_string()
    } else {
        state.mode.clone()
    };
    // The shell defaults WALLPAPER_SOURCE to "legacy" only when a state file
    // exists but omits it; with no state file at all it stays "flat".
    let current_source = if ctx.state_file().is_file() {
        if state.wallpaper_source.is_empty() {
            "legacy".to_string()
        } else {
            state.wallpaper_source.clone()
        }
    } else {
        "flat".to_string()
    };

    // 1. Flavor.
    let mut flavor_lines = String::new();
    for name in wallpaper::valid_flavors(ctx) {
        let label = Palette::load(ctx, &name).get("THEME_LABEL").to_string();
        let marker = if name == current_flavor { "✓ " } else { "" };
        flavor_lines.push_str(&format!("{marker}{name} — {label}\n"));
    }

    let current_source_label = source_label(&current_source);
    let current_flavor_disp = if current_flavor.is_empty() {
        "none"
    } else {
        &current_flavor
    };
    let flavor_choice = pick(
        &format!(
            "Theme flavor (current: {current_flavor_disp}; wallpaper: {current_source_label})"
        ),
        &flavor_lines,
    );
    if flavor_choice.is_empty() {
        return Ok(());
    }
    // Strip the " — <label>" suffix and the "✓ " marker prefix.
    let before_dash = flavor_choice
        .split_once(" —")
        .map(|(head, _)| head)
        .unwrap_or(&flavor_choice);
    let flavor = before_dash
        .strip_prefix("✓ ")
        .unwrap_or(before_dash)
        .to_string();

    if current_source == "user" {
        notify("Custom wallpaper will be preserved unless you choose a different background mode.");
    }

    // 2. Background mode.
    let current_mode_label_key = match current_mode.as_str() {
        "flat" => "flat".to_string(),
        "rotate" => "rotate".to_string(),
        "wallpaper" => match current_source.as_str() {
            "user" | "theme-default" => current_source.clone(),
            _ => "legacy".to_string(),
        },
        _ => "legacy".to_string(),
    };
    let current_mode_label = source_label(&current_mode_label_key);
    let mode_choice = pick(
        &format!("Background mode (current: {current_mode_label})"),
        "Plain color\nRotate wallpapers\nSelect wallpaper",
    );
    if mode_choice.is_empty() {
        return Ok(());
    }

    if mode_choice.starts_with("Plain color") {
        theme::run(ctx, &set_args(&flavor, &["--flat"]))?;
        notify(&format!("Set to {flavor} / plain color"));
    } else if mode_choice.starts_with("Rotate wallpapers") {
        let images = wallpaper::flavor_wallpapers(ctx, &flavor);
        if images.is_empty() {
            notify(&format!(
                "No wallpapers found in {} — add images before enabling rotation",
                ctx.wallpapers_dir().display()
            ));
            return Err(crate::error::Error::with_code("", 1));
        }
        let interval = pick(
            "Rotate interval (type a custom value, e.g. 45m)",
            "30m\n15m\n1h\n2h",
        );
        if interval.is_empty() {
            return Ok(());
        }
        theme::run(
            ctx,
            &set_args(&flavor, &["--rotate", "--interval", &interval]),
        )?;
        notify(&format!("Set to {flavor} / rotate every {interval}"));
    } else if mode_choice.starts_with("Select wallpaper") {
        let images = wallpaper::flavor_wallpapers(ctx, &flavor);
        if images.is_empty() {
            notify(&format!(
                "No wallpapers found in {} — add images first",
                ctx.wallpapers_dir().display()
            ));
            return Err(crate::error::Error::with_code("", 1));
        }
        let names: Vec<String> = images
            .iter()
            .filter_map(|p| p.file_name().and_then(|n| n.to_str()).map(String::from))
            .collect();
        let options = format!("{}\n", names.join("\n"));
        let choice = pick(&format!("Select wallpaper for {flavor}"), &options);
        if choice.is_empty() {
            return Ok(());
        }
        theme::run(ctx, &set_args(&flavor, &["--wallpaper", &choice]))?;
        notify(&format!("Set to {flavor} / {choice}"));
    }

    Ok(())
}

fn set_args(flavor: &str, tail: &[&str]) -> Vec<String> {
    let mut v = vec!["set".to_string(), flavor.to_string()];
    v.extend(tail.iter().map(|s| s.to_string()));
    v
}

// ── whichkey ────────────────────────────────────────────────────────────

pub fn run_whichkey(ctx: &Context, _args: &[String]) -> Result<()> {
    let config = resolved_sway_config(ctx);
    let mut lines = expand_bindings(&config);
    // `sort -u`: locale-sorted, de-duplicated.
    crate::collate::sort_strings(&mut lines);
    lines.dedup();

    // Reformat: `%-22s → %s` with the first whitespace field as the key.
    let mut rendered = String::new();
    for line in &lines {
        let mut fields = line.split_whitespace();
        let key = fields.next().unwrap_or("");
        let rest = fields.collect::<Vec<_>>().join(" ");
        rendered.push_str(&format!("{key:<22} → {rest}\n"));
    }

    // Feed to wofi; selection just closes the popup (read-only).
    if let Ok(mut child) = Command::new("wofi")
        .args([
            "--show",
            "dmenu",
            "--prompt",
            "which-key",
            "--width",
            "700",
            "--height",
            "600",
            "--lines",
            "20",
        ])
        .stdin(Stdio::piped())
        .stdout(Stdio::null())
        .spawn()
    {
        if let Some(mut stdin) = child.stdin.take() {
            let _ = stdin.write_all(rendered.as_bytes());
        }
        let _ = child.wait();
    }
    Ok(())
}

/// The live, resolved sway config (`swaymsg -t get_config | jq -r '.config'`)
/// when a sway session + jq are available; otherwise the on-disk config file.
fn resolved_sway_config(ctx: &Context) -> String {
    let have_tools = util::command_exists("swaymsg") && util::command_exists("jq");
    let session_ok = have_tools
        && Command::new("swaymsg")
            .args(["-t", "get_version"])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .map(|s| s.success())
            .unwrap_or(false);
    if session_ok {
        return sh_capture("swaymsg -t get_config | jq -r '.config'");
    }
    let config_path = std::env::var("SWAY_CONFIG").unwrap_or_else(|_| {
        ctx.home
            .join(".config/sway/config")
            .to_string_lossy()
            .into_owned()
    });
    std::fs::read_to_string(config_path).unwrap_or_default()
}

/// Reproduce the awk pass: collect `set $name value` definitions in order,
/// then emit each `bindsym`/`bindcode` line with its prefix stripped and every
/// `$var` reference literally substituted (in definition order, matching the
/// shell's `gsub` behaviour).
fn expand_bindings(config: &str) -> Vec<String> {
    let mut var_order: Vec<(String, String)> = Vec::new();
    let mut out: Vec<String> = Vec::new();

    for raw in config.lines() {
        let trimmed = raw.trim_start_matches([' ', '\t']);
        if let Some(rest) = set_var_line(trimmed) {
            var_order.push(rest);
            continue;
        }
        if let Some(binding) = strip_bind_prefix(trimmed) {
            let mut line = binding.to_string();
            for (name, val) in &var_order {
                line = line.replace(name.as_str(), val);
            }
            out.push(line);
        }
    }
    out
}

/// Parse `set $name value...` → (`$name`, normalized value with `"` removed
/// and internal whitespace collapsed, mirroring awk's field rebuild).
fn set_var_line(trimmed: &str) -> Option<(String, String)> {
    let mut fields = trimmed.split_whitespace();
    if fields.next()? != "set" {
        return None;
    }
    let name = fields.next()?;
    if !name.starts_with('$') || name.len() < 2 {
        return None;
    }
    if !name[1..]
        .bytes()
        .all(|b| b.is_ascii_alphanumeric() || b == b'_')
    {
        return None;
    }
    let val = fields.collect::<Vec<_>>().join(" ").replace('"', "");
    Some((name.to_string(), val))
}

/// Strip a leading `bindsym `/`bindcode ` (with surrounding whitespace as the
/// awk regex `^[ \t]*(bindsym|bindcode)[ \t]+` did). Returns the remainder,
/// preserving its internal spacing.
fn strip_bind_prefix(trimmed: &str) -> Option<&str> {
    for kw in ["bindsym", "bindcode"] {
        if let Some(rest) = trimmed.strip_prefix(kw) {
            let after = rest.trim_start_matches([' ', '\t']);
            if after.len() < rest.len() {
                // There was at least one separating space/tab.
                return Some(after);
            }
        }
    }
    None
}
