//! Best-effort live refresh and the systemd wallpaper-rotation timer.

use crate::context::Context;
use crate::util;
use std::env;
use std::fs;
use std::process::Command;

fn skip_reload() -> bool {
    env::var_os("CUMULUS_SKIP_RELOAD").is_some()
}
fn skip_systemd() -> bool {
    env::var_os("CUMULUS_SKIP_SYSTEMD").is_some()
}

/// Run the runtime-refresh coordinator (best-effort, in-process).
pub fn reload_apps(ctx: &Context) {
    if skip_reload() {
        return;
    }
    let _ = crate::refresh::run_runtime_refresh(ctx);
}

/// Write and enable the systemd --user rotation timer.
pub fn write_rotate_units(ctx: &Context, interval: &str) {
    if skip_systemd() {
        return;
    }
    let dir = ctx.systemd_user_dir();
    if fs::create_dir_all(&dir).is_err() {
        return;
    }
    // The rotation tick runs the installed cumulus-theme binary. %h expands to
    // the user's home; cargo installs binaries into ~/.cargo/bin.
    let service = "[Unit]\nDescription=cumulus.dotfiles wallpaper rotation (single tick)\n\n\
[Service]\nType=oneshot\nExecStart=%h/.cargo/bin/cumulus-theme next\n"
        .to_string();
    let timer = format!(
        "[Unit]\nDescription=cumulus.dotfiles wallpaper rotation timer\n\n\
[Timer]\nOnBootSec={interval}\nOnUnitActiveSec={interval}\nPersistent=true\n\n\
[Install]\nWantedBy=timers.target\n"
    );
    let _ = fs::write(dir.join("cumulus-wallpaper-rotate.service"), service);
    let _ = fs::write(dir.join("cumulus-wallpaper-rotate.timer"), timer);
    let _ = Command::new("systemctl")
        .args(["--user", "daemon-reload"])
        .status();
    let _ = Command::new("systemctl")
        .args([
            "--user",
            "enable",
            "--now",
            "cumulus-wallpaper-rotate.timer",
        ])
        .status();
    util::log(
        "theme",
        &format!(
            "Enabled rotation timer: every {interval} (systemctl --user status cumulus-wallpaper-rotate.timer)"
        ),
    );
}

/// Disable the rotation timer if present (best-effort).
pub fn disable_rotate_units(_ctx: &Context) {
    if skip_systemd() {
        return;
    }
    let listed = Command::new("systemctl")
        .args(["--user", "list-unit-files"])
        .output();
    let has_timer = matches!(listed, Ok(out)
        if String::from_utf8_lossy(&out.stdout).contains("cumulus-wallpaper-rotate.timer"));
    if has_timer {
        let _ = Command::new("systemctl")
            .args([
                "--user",
                "disable",
                "--now",
                "cumulus-wallpaper-rotate.timer",
            ])
            .status();
        util::log("theme", "Disabled rotation timer.");
    }
}
