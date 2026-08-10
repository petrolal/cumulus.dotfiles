//! Best-effort runtime refresh of running apps after a theme change, plus the
//! OS/GTK color-scheme and hardware-RGB adapters. Ports `runtime-refresh.sh`,
//! `os-colorscheme.sh`, and `rgb-theme.sh`.
//!
//! Every adapter is best-effort: persisted theme state stays authoritative when
//! an application is unavailable or has no safe runtime endpoint.

use crate::context::Context;
use crate::error::{Error, Result};
use crate::theme::palette::Palette;
use crate::util;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

/// Run an external command with all stdio discarded; return whether it exited 0.
fn quiet_ok(cmd: &mut Command) -> bool {
    cmd.stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

// ---------------------------------------------------------------------------
// runtime-refresh
// ---------------------------------------------------------------------------

fn refresh_sway() -> bool {
    if !util::command_exists("swaymsg") {
        return false;
    }
    if !quiet_ok(Command::new("swaymsg").args(["-t", "get_version"])) {
        return false;
    }
    quiet_ok(Command::new("swaymsg").arg("reload"))
}

fn refresh_waybar() -> bool {
    if !util::command_exists("pgrep") {
        return false;
    }
    if !quiet_ok(Command::new("pgrep").args(["-x", "waybar"])) {
        return false;
    }
    quiet_ok(Command::new("pkill").args(["-USR2", "-x", "waybar"]))
}

fn refresh_kitty(ctx: &Context, user: &str) -> bool {
    if !util::command_exists("kitty") {
        return false;
    }
    let socket = std::env::var_os("CUMULUS_KITTY_SOCKET")
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            let base = std::env::var_os("XDG_RUNTIME_DIR")
                .map(PathBuf::from)
                .unwrap_or_else(|| PathBuf::from("/tmp"));
            base.join("cumulus-kitty")
        });
    if !util::is_socket(&socket) {
        return false;
    }
    if util::path_owner(&socket).as_deref() != Some(user) {
        return false;
    }
    let colors = ctx.dotfiles_dir.join("config/kitty/colors.conf");
    quiet_ok(Command::new("kitty").args([
        "@".as_ref(),
        "--to".as_ref(),
        format!("unix:{}", socket.display()).as_ref(),
        "set-colors".as_ref(),
        "--all".as_ref(),
        "--configured".as_ref(),
        colors.as_os_str(),
    ]))
}

fn refresh_wofi() -> bool {
    if !util::command_exists("pgrep") {
        return false;
    }
    if !quiet_ok(Command::new("pgrep").args(["-x", "wofi"])) {
        return false;
    }
    quiet_ok(Command::new("pkill").args(["-TERM", "-x", "wofi"]))
}

fn refresh_nvim_socket(socket: &Path, user: &str) -> bool {
    if !util::is_socket(socket) {
        return false;
    }
    if util::path_owner(socket).as_deref() != Some(user) {
        return false;
    }
    quiet_ok(Command::new("timeout").args([
        "5s".as_ref(),
        "nvim".as_ref(),
        "--headless".as_ref(),
        "--server".as_ref(),
        socket.as_os_str(),
        "--remote-send".as_ref(),
        r#"<Cmd>lua require("cumulus.theme").load_saved_theme()<CR>"#.as_ref(),
    ]))
}

/// Collect candidate nvim server sockets in the same order the shell globs them.
fn nvim_sockets() -> Vec<PathBuf> {
    let mut sockets = Vec::new();
    // $XDG_RUNTIME_DIR/nvim/*.sock
    if let Some(xdg) = std::env::var_os("XDG_RUNTIME_DIR") {
        collect_matching(
            &PathBuf::from(xdg).join("nvim"),
            |name| name.ends_with(".sock"),
            &mut sockets,
        );
    }
    // ${TMPDIR:-/tmp}/nvim.*.sock
    let tmpdir = std::env::var_os("TMPDIR")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("/tmp"));
    collect_matching(
        &tmpdir,
        |name| name.starts_with("nvim.") && name.ends_with(".sock"),
        &mut sockets,
    );
    // /tmp/nvim.*.sock
    collect_matching(
        Path::new("/tmp"),
        |name| name.starts_with("nvim.") && name.ends_with(".sock"),
        &mut sockets,
    );
    sockets
}

fn collect_matching(dir: &Path, pred: impl Fn(&str) -> bool, out: &mut Vec<PathBuf>) {
    let Ok(entries) = std::fs::read_dir(dir) else {
        return;
    };
    let mut matched: Vec<PathBuf> = entries
        .flatten()
        .filter(|e| e.file_name().to_str().map(&pred).unwrap_or(false))
        .map(|e| e.path())
        .collect();
    matched.sort();
    out.extend(matched);
}

fn refresh_nvim(user: &str) -> bool {
    if !util::command_exists("nvim") {
        return false;
    }
    let mut found = false;
    let mut refreshed = false;
    for socket in nvim_sockets() {
        if !socket.exists() {
            continue;
        }
        found = true;
        if refresh_nvim_socket(&socket, user) {
            refreshed = true;
        } else {
            util::log(
                "theme-refresh",
                &format!(
                    "neovim: unreachable or rejected socket {}",
                    util::basename(&socket.to_string_lossy())
                ),
            );
        }
    }
    found && refreshed
}

fn run_adapter(name: &str, ok: bool, refreshed: &mut u32, deferred: &mut u32) {
    if ok {
        util::log("theme-refresh", &format!("{name}: refreshed"));
        *refreshed += 1;
    } else {
        util::log("theme-refresh", &format!("{name}: deferred or unavailable"));
        *deferred += 1;
    }
}

/// `cumulus-runtime-refresh` — refresh all supported running applications.
pub fn run_runtime_refresh(ctx: &Context) -> Result<()> {
    if !ctx.state_file().is_file() {
        util::log("theme-refresh", "No theme state; nothing to refresh.");
        return Ok(());
    }
    let user = util::current_username().unwrap_or_default();
    let mut refreshed = 0u32;
    let mut deferred = 0u32;
    run_adapter("sway", refresh_sway(), &mut refreshed, &mut deferred);
    run_adapter("waybar", refresh_waybar(), &mut refreshed, &mut deferred);
    run_adapter(
        "kitty",
        refresh_kitty(ctx, &user),
        &mut refreshed,
        &mut deferred,
    );
    run_adapter("wofi", refresh_wofi(), &mut refreshed, &mut deferred);
    run_adapter("neovim", refresh_nvim(&user), &mut refreshed, &mut deferred);
    run_adapter(
        "os/gtk",
        os_colorscheme_apply(),
        &mut refreshed,
        &mut deferred,
    );
    run_adapter("rgb", rgb_apply(ctx, None), &mut refreshed, &mut deferred);
    if deferred == 0 {
        util::log(
            "theme-refresh",
            &format!("Refresh result: complete ({refreshed} adapters refreshed)"),
        );
    } else {
        util::log(
            "theme-refresh",
            &format!("Refresh result: partial ({refreshed} refreshed, {deferred} deferred)"),
        );
    }
    Ok(())
}

// ---------------------------------------------------------------------------
// os-colorscheme
// ---------------------------------------------------------------------------

/// Apply the GNOME/GTK color-scheme; always "succeeds" (deferred == no-op).
fn os_colorscheme_apply() -> bool {
    if !util::command_exists("gsettings") {
        util::log("os-theme", "deferred: gsettings is unavailable");
        return true;
    }
    let writable = quiet_ok(Command::new("gsettings").args([
        "writable",
        "org.gnome.desktop.interface",
        "color-scheme",
    ]));
    if !writable {
        util::log(
            "os-theme",
            "deferred: OS color-scheme setting is unavailable",
        );
        return true;
    }
    // All remaining flavors (aws/azure/gcp/oci) are dark palettes.
    let scheme = "prefer-dark";
    let _ = quiet_ok(Command::new("gsettings").args([
        "set",
        "org.gnome.desktop.interface",
        "color-scheme",
        scheme,
    ]));
    util::log("os-theme", &format!("set color scheme: {scheme}"));
    true
}

/// `cumulus-os-colorscheme` — synchronize the optional GNOME/GTK color-scheme.
pub fn run_os_colorscheme(_ctx: &Context) -> Result<()> {
    os_colorscheme_apply();
    Ok(())
}

// ---------------------------------------------------------------------------
// rgb-theme
// ---------------------------------------------------------------------------

/// Apply the active theme color to any supported hardware RGB controllers.
/// Returns whether at least one controller was updated.
fn rgb_apply(ctx: &Context, flavor_arg: Option<&str>) -> bool {
    // Resolve the flavor: explicit arg, else saved state, else oci.
    let mut flavor = flavor_arg.map(str::to_string).unwrap_or_default();
    if flavor.is_empty() {
        let state = crate::theme::state::State::load(ctx);
        flavor = state.flavor;
    }
    if flavor.is_empty() {
        flavor = "oci".to_string();
    }

    // Load the palette, falling back to oci when the flavor file is missing.
    let conf_path = ctx.palettes_dir().join(format!("{flavor}.conf"));
    let sh_path = ctx.palettes_dir().join(format!("{flavor}.sh"));
    let palette = if conf_path.is_file() || sh_path.is_file() {
        Palette::load(ctx, &flavor)
    } else {
        Palette::load(ctx, "oci")
    };

    let raw = {
        let b = palette.get("BLUE");
        if b.is_empty() {
            "#0073bb".to_string()
        } else {
            b.to_string()
        }
    };
    let hex = raw.strip_prefix('#').unwrap_or(&raw).to_string();

    let mut updated = false;

    // 1. OpenRGB (motherboard, RAM, GPU, mouse, USB keyboards, addressable RGB).
    if util::command_exists("openrgb")
        && (quiet_ok(Command::new("openrgb").args(["--color", &hex, "--mode", "static"]))
            || quiet_ok(Command::new("openrgb").args(["--color", &hex])))
    {
        updated = true;
    }
    // 2. asusctl (ASUS ROG/TUF laptop keyboard RGB).
    if util::command_exists("asusctl")
        && quiet_ok(Command::new("asusctl").args(["led-mode", "static", "-c", &hex]))
    {
        updated = true;
    }
    // 3. liquidctl (liquid coolers & fan controllers).
    if util::command_exists("liquidctl")
        && (quiet_ok(Command::new("liquidctl").args(["set", "ring", "color", "fixed", &hex]))
            || quiet_ok(Command::new("liquidctl").args(["set", "sync", "color", "fixed", &hex])))
    {
        updated = true;
    }

    updated
}

/// `cumulus-rgb-theme [flavor]` — synchronize hardware RGB lighting.
///
/// Exits `0` when a controller was updated, `1` otherwise (silent, mirroring
/// the shell script so it composes as a best-effort adapter).
pub fn run_rgb_theme(ctx: &Context, args: &[String]) -> Result<()> {
    let flavor = args.first().map(String::as_str);
    if rgb_apply(ctx, flavor) {
        Ok(())
    } else {
        Err(Error::with_code("", 1))
    }
}
