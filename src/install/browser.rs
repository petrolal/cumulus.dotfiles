//! `cumulus-install-browser` — install Google Chrome and set it as the default
//! browser. Ports `install-browser.sh`.

use super::{have, parse_dry_run, sh_capture, Installer};
use crate::context::Context;
use crate::error::{Error, Result};

const HELP: &str = "\
install-browser.sh — install Google Chrome and set it as the default browser.

Ubuntu/Debian (apt): downloads Google's official .deb. Arch: via an AUR
helper (yay/paru) if present.

Usage:
  cumulus-install-browser            # install + set as default browser
  cumulus-install-browser --dry-run  # preview commands, change nothing
";

const DESKTOP_FILE: &str = "google-chrome.desktop";

pub fn run(ctx: &Context, args: &[String]) -> Result<()> {
    let Some(dry_run) = parse_dry_run(args, HELP)? else {
        return Ok(());
    };
    let inst = Installer::new("browser", dry_run);
    if dry_run {
        inst.log("DRY RUN — no changes will be made");
    }

    if have("apt") {
        install_chrome_apt(&inst);
    } else if have("pacman") {
        install_chrome_pacman(&inst);
    } else {
        inst.log("Neither apt nor pacman found — unsupported distro for this script.");
        return Err(Error::with_code("", 1));
    }
    set_default_browser(&inst);
    if !dry_run {
        verify(ctx, &inst);
    }
    inst.log("Done. Launch Chrome with $mod+Shift+b (after reloading sway: $mod+Shift+c).");
    Ok(())
}

fn install_chrome_apt(inst: &Installer) {
    if have("google-chrome-stable") || have("google-chrome") {
        inst.log("OK (already installed): google-chrome");
        return;
    }
    inst.log("Downloading Google Chrome .deb...");
    inst.run("curl -fsSL -o /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb");
    inst.log("Installing (registers Google's apt repo for future updates)...");
    inst.run("sudo apt update");
    inst.run("sudo apt install -y /tmp/google-chrome-stable_current_amd64.deb");
    inst.run("rm -f /tmp/google-chrome-stable_current_amd64.deb");
}

fn install_chrome_pacman(inst: &Installer) {
    if have("google-chrome-stable") {
        inst.log("OK (already installed): google-chrome-stable");
        return;
    }
    let helper = if have("yay") {
        "yay"
    } else if have("paru") {
        "paru"
    } else {
        ""
    };
    if helper.is_empty() {
        inst.log("No AUR helper (yay/paru) found — Chrome isn't in the official Arch repos.");
        inst.log("Install one first (e.g. https://github.com/Jguer/yay), then run:");
        inst.log("  yay -S google-chrome");
        return;
    }
    inst.log(&format!(
        "Installing google-chrome from AUR via {helper}..."
    ));
    inst.run(&format!("{helper} -S --needed --noconfirm google-chrome"));
}

fn set_default_browser(inst: &Installer) {
    if !have("google-chrome-stable") && !have("google-chrome") {
        inst.log("google-chrome not found on PATH — skipping default-browser setup.");
        return;
    }
    if !have("xdg-settings") {
        inst.log("xdg-settings not found — install xdg-utils to set the default browser.");
        return;
    }
    inst.log(&format!("Setting {DESKTOP_FILE} as the default browser..."));
    inst.run(&format!(
        "xdg-settings set default-web-browser '{DESKTOP_FILE}'"
    ));
    for mime in [
        "x-scheme-handler/http",
        "x-scheme-handler/https",
        "x-scheme-handler/about",
        "x-scheme-handler/unknown",
        "text/html",
        "application/xhtml+xml",
    ] {
        inst.run(&format!("xdg-mime default '{DESKTOP_FILE}' '{mime}'"));
    }
}

fn verify(ctx: &Context, inst: &Installer) {
    let current = sh_capture("xdg-settings get default-web-browser 2>/dev/null || echo unknown");
    inst.log(&format!("Default browser is now: {current}"));
    let sway_config = ctx.dotfiles_dir.join("config/sway/config");
    let has_binding = std::fs::read_to_string(&sway_config)
        .map(|c| c.contains("exec google-chrome-stable"))
        .unwrap_or(false);
    if has_binding {
        inst.log("Sway keybinding OK: $mod+Shift+b launches google-chrome-stable");
    } else {
        inst.log("NOTE: no $mod+Shift+b browser keybinding found in config/sway/config");
        inst.log("      (expected if you haven't pulled the latest cumulus.dotfiles config yet)");
    }
}
