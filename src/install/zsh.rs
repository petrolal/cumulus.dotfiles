//! `cumulus-install-zsh` — install zsh + oh-my-zsh, set default shell/editor.
//! Ports `install-zsh.sh`.

use super::{have, parse_dry_run, sh_capture, Installer};
use crate::context::Context;
use crate::error::{Error, Result};

const HELP: &str = "\
install-zsh.sh — install zsh + oh-my-zsh (Cloud theme), ensure the Nerd Font
is present, and make Neovim the default editor.

Usage:
  cumulus-install-zsh            # install everything
  cumulus-install-zsh --dry-run  # preview commands, change nothing
";

fn username() -> String {
    std::env::var("USER")
        .ok()
        .or_else(crate::util::current_username)
        .unwrap_or_default()
}

pub fn run(ctx: &Context, args: &[String]) -> Result<()> {
    let Some(dry_run) = parse_dry_run(args, HELP)? else {
        return Ok(());
    };
    let inst = Installer::new("zsh", dry_run);
    if dry_run {
        inst.log("DRY RUN — no changes will be made");
    }

    install_zsh(&inst)?;
    install_oh_my_zsh(ctx, &inst);
    set_default_shell(&inst);
    install_nerd_font(ctx, &inst)?;
    set_default_editor(&inst);

    inst.log("Done. Run ./install.sh to symlink zsh/.zshrc and zsh/zsh_config/ into place,");
    inst.log("then open a new terminal (or 'exec zsh') to see the Cloud theme.");
    Ok(())
}

fn install_zsh(inst: &Installer) -> Result<()> {
    if have("zsh") {
        inst.log("OK (already installed): zsh");
        return Ok(());
    }
    if have("apt") {
        inst.run("sudo apt update && sudo apt install -y zsh");
    } else if have("pacman") {
        inst.run("sudo pacman -Syu --needed --noconfirm zsh");
    } else {
        inst.log("No supported package manager found (apt/pacman) — install zsh manually.");
        return Err(Error::with_code("", 1));
    }
    Ok(())
}

fn install_oh_my_zsh(ctx: &Context, inst: &Installer) {
    if ctx.home.join(".oh-my-zsh").is_dir() {
        inst.log("OK (already installed): oh-my-zsh");
        return;
    }
    inst.log("Installing oh-my-zsh (unattended, keeping our own .zshrc)...");
    inst.run("RUNZSH=no KEEP_ZSHRC=yes CHSH=no sh -c \"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\"");
}

fn set_default_shell(inst: &Installer) {
    let zsh_path = which("zsh").unwrap_or_default();
    if zsh_path.is_empty() {
        inst.log("zsh not found on PATH — skipping default shell change");
        return;
    }
    let user = username();
    let login = std::env::var("LOGNAME")
        .or_else(|_| std::env::var("USER"))
        .unwrap_or_default();
    let user_shell = sh_capture(&format!(
        "getent passwd \"{login}\" 2>/dev/null | cut -d: -f7 || echo \"${{SHELL:-}}\""
    ));
    let real_user_shell = sh_capture(&format!(
        "readlink -f \"{user_shell}\" 2>/dev/null || echo \"{user_shell}\""
    ));
    let real_zsh_path = sh_capture(&format!(
        "readlink -f \"{zsh_path}\" 2>/dev/null || echo \"{zsh_path}\""
    ));
    if !real_user_shell.is_empty() && !real_zsh_path.is_empty() && real_user_shell == real_zsh_path
    {
        inst.log(&format!("OK (already default shell): zsh ({user_shell})"));
        return;
    }

    inst.log("Setting zsh as default login shell...");
    if inst.dry_run() {
        println!("+ chsh -s '{zsh_path}' '{user}'");
        return;
    }

    // chsh talks to /etc/passwd directly; on AD/LDAP/SSSD accounts it fails
    // even though the account resolves via NSS. Fall back to usermod.
    let chsh_ok = std::process::Command::new("chsh")
        .args(["-s", &zsh_path, &user])
        .status()
        .map(|s| s.success())
        .unwrap_or(false);
    if chsh_ok {
        return;
    }
    inst.log("chsh failed (likely an AD/LDAP/SSSD-managed account, not local /etc/passwd):");
    inst.log("Falling back to usermod...");
    if inst.run(&format!("sudo usermod -s '{zsh_path}' '{user}'")) {
        inst.log("Default shell set via usermod.");
    } else {
        inst.log("WARN: could not change default shell (chsh and usermod both failed).");
        inst.log("  This account is likely managed centrally (AD/LDAP) — ask your admin to");
        inst.log(&format!(
            "  update the loginShell attribute, or add: exec {zsh_path}  to ~/.bash_profile"
        ));
    }
}

fn install_nerd_font(ctx: &Context, inst: &Installer) -> Result<()> {
    // Reuse the fonts installer with the same dry-run flag.
    let args: Vec<String> = if inst.dry_run() {
        vec!["--dry-run".to_string()]
    } else {
        Vec::new()
    };
    super::fonts::run(ctx, &args)
}

fn set_default_editor(inst: &Installer) {
    let nvim_path = which("nvim").unwrap_or_default();
    if nvim_path.is_empty() {
        inst.log("nvim not found — install it first (see scripts/install-nvim-deps.sh), skipping default-editor setup");
        return;
    }
    inst.log("Setting nvim as default editor (git core.editor)...");
    inst.run(&format!("git config --global core.editor '{nvim_path}'"));
    if have("update-alternatives") {
        inst.log("Registering nvim with update-alternatives (editor)...");
        inst.run(&format!(
            "sudo update-alternatives --install /usr/bin/editor editor '{nvim_path}' 100"
        ));
        inst.run(&format!(
            "sudo update-alternatives --set editor '{nvim_path}'"
        ));
    }
    inst.log("EDITOR/VISUAL are also exported from zsh/zsh_config/40-environment.zsh");
}

fn which(bin: &str) -> Option<String> {
    let path = std::env::var_os("PATH")?;
    std::env::split_paths(&path)
        .map(|d| d.join(bin))
        .find(|p| crate::util::is_executable(p))
        .map(|p| p.to_string_lossy().into_owned())
}
