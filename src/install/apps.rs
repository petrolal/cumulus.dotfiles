//! `cumulus-install-apps` — install the default desktop applications. Ports
//! `install-apps.sh` (apt+snap on Debian/Ubuntu, pacman+AUR on Arch).

use super::{have, parse_dry_run, Installer};
use crate::context::Context;
use crate::error::{Error, Result};

const HELP: &str = "\
install-apps.sh — install the default applications this workstation relies on.

Supports Ubuntu/Debian (apt + snap) and Arch (pacman + AUR via yay/paru).

Usage:
  cumulus-install-apps            # install everything
  cumulus-install-apps --dry-run  # preview commands, change nothing
";

const APT_PACKAGES: &str = "microsoft-edge-stable code gh docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin thunderbird network-manager-gnome blueman sway-notification-center policykit-1";
const SNAP_PACKAGES: [&str; 2] = ["firefox", "telegram-desktop"];
const SNAP_CLASSIC_PACKAGES: [&str; 4] = ["1password", "intellij-idea", "obsidian", "yazi"];
const PACMAN_PACKAGES: &str = "github-cli docker docker-buildx docker-compose thunderbird network-manager-applet blueman polkit firefox telegram-desktop yazi";
const AUR_PACKAGES: &str = "microsoft-edge-stable-bin visual-studio-code-bin sway-notification-center 1password intellij-idea-ultimate-edition obsidian";

pub fn run(_ctx: &Context, args: &[String]) -> Result<()> {
    let Some(dry_run) = parse_dry_run(args, HELP)? else {
        return Ok(());
    };
    let inst = Installer::new("apps", dry_run);
    if dry_run {
        inst.log("DRY RUN — no changes will be made");
    }

    if have("apt") {
        install_apt(&inst);
        install_snaps(&inst);
    } else if have("pacman") {
        install_pacman(&inst);
        install_aur(&inst);
    } else {
        inst.log("No supported package manager found (apt/pacman) — install manually:");
        inst.log(&format!("  {APT_PACKAGES}"));
        return Err(Error::with_code("", 1));
    }

    install_spotify_player(&inst);
    inst.log("Done. Add yourself to the docker group if needed: sudo usermod -aG docker $USER (then re-login)");
    Ok(())
}

fn install_apt(inst: &Installer) {
    inst.log(&format!("Installing apt packages: {APT_PACKAGES}"));
    inst.run("sudo apt update");
    inst.run(&format!("sudo apt install -y {APT_PACKAGES}"));
}

fn install_snaps(inst: &Installer) {
    if !have("snap") {
        inst.log("snapd not found — skipping snap installs");
        return;
    }
    for pkg in SNAP_PACKAGES {
        inst.log(&format!("Installing snap: {pkg}"));
        inst.run(&format!("sudo snap install '{pkg}'"));
    }
    for pkg in SNAP_CLASSIC_PACKAGES {
        inst.log(&format!("Installing snap (classic): {pkg}"));
        inst.run(&format!("sudo snap install '{pkg}' --classic"));
    }
}

fn install_pacman(inst: &Installer) {
    inst.log(&format!("Installing pacman packages: {PACMAN_PACKAGES}"));
    inst.run(&format!(
        "sudo pacman -Syu --needed --noconfirm {PACMAN_PACKAGES}"
    ));
}

fn install_aur(inst: &Installer) {
    let helper = if have("yay") {
        "yay"
    } else if have("paru") {
        "paru"
    } else {
        ""
    };
    if helper.is_empty() {
        inst.log(&format!(
            "No AUR helper (yay/paru) found — skipping: {AUR_PACKAGES}"
        ));
        inst.log("Install an AUR helper (e.g. https://github.com/Jguer/yay), then run:");
        inst.log(&format!("  yay -S {AUR_PACKAGES}"));
        return;
    }
    inst.log(&format!(
        "Installing AUR packages via {helper}: {AUR_PACKAGES}"
    ));
    inst.run(&format!("{helper} -S --needed --noconfirm {AUR_PACKAGES}"));
}

fn install_spotify_player(inst: &Installer) {
    if !have("cargo") {
        inst.log(
            "cargo not found — skipping spotify_player (install Rust first: https://rustup.rs)",
        );
        return;
    }
    if have("spotify_player") {
        inst.log("OK (already installed): spotify_player");
        return;
    }
    inst.log("Installing spotify_player via cargo...");
    inst.run("cargo install spotify_player");
}
