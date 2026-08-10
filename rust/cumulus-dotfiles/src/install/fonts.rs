//! `cumulus-install-fonts` — install the JetBrainsMono Nerd Font. Ports
//! `install-fonts.sh`.

use super::{parse_dry_run, Installer};
use crate::context::Context;
use crate::error::Result;

const HELP: &str = "\
install-fonts.sh — install the JetBrainsMono Nerd Font used across this
repo's kitty/waybar/wofi/sway configs.

Usage:
  cumulus-install-fonts            # install if missing
  cumulus-install-fonts --dry-run  # preview commands, change nothing
";

const NERD_FONT_NAME: &str = "JetBrainsMono";
const NERD_FONT_VERSION: &str = "v3.2.1";

pub fn run(ctx: &Context, args: &[String]) -> Result<()> {
    let Some(dry_run) = parse_dry_run(args, HELP)? else {
        return Ok(());
    };
    let inst = Installer::new("fonts", dry_run);
    if dry_run {
        inst.log("DRY RUN — no changes will be made");
    }
    install_nerd_font(ctx, &inst);
    Ok(())
}

fn install_nerd_font(ctx: &Context, inst: &Installer) {
    let match_count =
        super::sh_capture("fc-list 2>/dev/null | grep -ci \"JetBrainsMono Nerd Font\" || true");
    let count: u32 = match_count.trim().parse().unwrap_or(0);
    if count > 0 {
        inst.log(&format!(
            "OK (already installed): {NERD_FONT_NAME} Nerd Font"
        ));
        return;
    }
    let fonts_dir = ctx.home.join(".local/share/fonts");
    let fonts_dir = fonts_dir.to_string_lossy();
    inst.log(&format!(
        "Installing {NERD_FONT_NAME} Nerd Font {NERD_FONT_VERSION}..."
    ));
    inst.run(&format!("mkdir -p '{fonts_dir}'"));
    inst.run(&format!(
        "curl -fLo /tmp/{NERD_FONT_NAME}.zip     'https://github.com/ryanoasis/nerd-fonts/releases/download/{NERD_FONT_VERSION}/{NERD_FONT_NAME}.zip'"
    ));
    inst.run(&format!(
        "unzip -o -q /tmp/{NERD_FONT_NAME}.zip -d '{fonts_dir}' '*.ttf'"
    ));
    inst.run(&format!("rm -f /tmp/{NERD_FONT_NAME}.zip"));
    inst.run(&format!("fc-cache -f '{fonts_dir}'"));
    inst.log(&format!(
        "Installed. kitty/waybar/wofi/sway in this repo already default to '{NERD_FONT_NAME} Nerd Font'."
    ));
}
