//! `cumulus-install-nvim-deps` — install Neovim + its ecosystem dependencies.
//! Ports `install-nvim-deps.sh`.

use super::{have, parse_dry_run, sh_capture, Installer};
use crate::context::Context;
use crate::error::{Error, Result};

const HELP: &str = "\
install-nvim-deps.sh — install the latest Neovim plus everything its plugin
ecosystem needs (luarocks, imagemagick, python, nvm/node, tree-sitter-cli,
ripgrep, fd, lazygit, lazydocker, mermaid-cli).

Supports Ubuntu (apt) and Arch (pacman).

Usage:
  cumulus-install-nvim-deps            # install everything
  cumulus-install-nvim-deps --dry-run  # preview commands, change nothing
";

const NVIM_INSTALL_DIR: &str = "/opt/nvim-linux-x86_64";

fn nvm_dir(ctx: &Context) -> String {
    std::env::var("NVM_DIR")
        .unwrap_or_else(|_| ctx.home.join(".nvm").to_string_lossy().into_owned())
}

pub fn run(ctx: &Context, args: &[String]) -> Result<()> {
    let Some(dry_run) = parse_dry_run(args, HELP)? else {
        return Ok(());
    };
    let inst = Installer::new("nvim-deps", dry_run);
    if dry_run {
        inst.log("DRY RUN — no changes will be made");
    }

    install_system_packages(ctx, &inst)?;
    install_neovim(&inst);
    install_nvm_node(ctx, &inst);
    install_npm_globals(ctx, &inst);
    install_lazygit(ctx, &inst);
    install_lazydocker(&inst);

    inst.log("Done.");
    inst.log("telescope.nvim is a plugin managed by this repo's nvim config (lazy.nvim)");
    inst.log("— it will install/build itself the next time you launch nvim.");
    inst.log("Open a new shell (or 'source ~/.zshrc') to pick up nvm/node/npm on PATH.");
    Ok(())
}

fn install_system_packages(ctx: &Context, inst: &Installer) -> Result<()> {
    let home = ctx.home.to_string_lossy();
    if have("apt") {
        inst.log("Installing base packages via apt...");
        inst.run("sudo apt update");
        inst.run("sudo apt install -y luarocks imagemagick python3 python3-pip python3-venv pipx ripgrep fd-find curl unzip build-essential");
        if have("fdfind") && !have("fd") {
            inst.run(&format!("mkdir -p '{home}/.local/bin'"));
            inst.run(&format!(
                "ln -sf \"$(command -v fdfind)\" '{home}/.local/bin/fd'"
            ));
        }
    } else if have("pacman") {
        inst.log("Installing base packages via pacman...");
        inst.run("sudo pacman -Syu --needed --noconfirm luarocks imagemagick python python-pip python-pipx ripgrep fd curl unzip base-devel");
    } else {
        inst.log("No supported package manager found (apt/pacman) — install manually:");
        inst.log("  luarocks imagemagick python3 pip pipx ripgrep fd curl unzip");
        return Err(Error::with_code("", 1));
    }
    Ok(())
}

fn install_neovim(inst: &Installer) {
    let arch = sh_capture("uname -m");
    if arch != "x86_64" {
        inst.log(&format!(
            "Unsupported arch for the prebuilt Neovim tarball ({arch}) — install Neovim manually for your platform."
        ));
        return;
    }

    let nvim_tag = sh_capture(
        "curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest | grep -Po '\"tag_name\": *\"\\K[^\"]+' || true",
    );
    let latest_url = if !nvim_tag.is_empty() {
        inst.log(&format!("Latest stable Neovim release: {nvim_tag}"));
        format!("https://github.com/neovim/neovim/releases/download/{nvim_tag}/nvim-linux-x86_64.tar.gz")
    } else {
        inst.log("WARN: could not resolve latest stable tag via GitHub API; falling back to the /releases/latest redirect.");
        "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
            .to_string()
    };

    inst.log("Downloading latest stable Neovim release...");
    inst.run(&format!(
        "curl -fL '{latest_url}' -o /tmp/nvim-linux-x86_64.tar.gz"
    ));
    inst.run(&format!("sudo rm -rf '{NVIM_INSTALL_DIR}'"));
    inst.run("sudo tar -C /opt -xzf /tmp/nvim-linux-x86_64.tar.gz");
    inst.run(&format!(
        "sudo ln -sf '{NVIM_INSTALL_DIR}/bin/nvim' /usr/local/bin/nvim"
    ));
    inst.run("rm -f /tmp/nvim-linux-x86_64.tar.gz");

    if inst.dry_run() {
        inst.log("Neovim installed: (skipped in dry-run)");
    } else {
        inst.log(&format!(
            "Neovim installed: {}",
            sh_capture(&format!(
                "\"{NVIM_INSTALL_DIR}/bin/nvim\" --version | head -1"
            ))
        ));
    }
}

fn install_nvm_node(ctx: &Context, inst: &Installer) {
    let nvm_dir = nvm_dir(ctx);
    if file_nonempty(&format!("{nvm_dir}/nvm.sh")) {
        inst.log("OK (already installed): nvm");
    } else {
        inst.log("Installing nvm...");
        inst.run(
            "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash",
        );
    }

    if inst.dry_run() {
        inst.log("+ (dry-run) nvm install node --latest-npm && nvm alias default node");
        return;
    }

    inst.log("Installing latest Node.js + npm via nvm...");
    let _ = std::process::Command::new("bash")
        .args([
            "-c",
            &format!(
                ". \"{nvm_dir}/nvm.sh\" && nvm install node --latest-npm && nvm alias default node"
            ),
        ])
        .status();
    let node = sh_capture(&format!(". \"{nvm_dir}/nvm.sh\" >/dev/null 2>&1; node -v"));
    let npm = sh_capture(&format!(". \"{nvm_dir}/nvm.sh\" >/dev/null 2>&1; npm -v"));
    inst.log(&format!("Node: {node}  npm: {npm}"));
}

fn install_npm_globals(ctx: &Context, inst: &Installer) {
    if inst.dry_run() {
        inst.log("+ npm install -g tree-sitter-cli @mermaid-js/mermaid-cli");
        return;
    }
    let nvm_dir = nvm_dir(ctx);
    let npm_bin = sh_capture(&format!(
        "[ -s \"{nvm_dir}/nvm.sh\" ] && . \"{nvm_dir}/nvm.sh\" >/dev/null 2>&1; command -v npm || true"
    ));
    if npm_bin.is_empty() {
        inst.log(
            "npm not found on PATH — skipping tree-sitter-cli/mermaid-cli (install Node first)",
        );
        return;
    }
    inst.log("Installing tree-sitter-cli and mermaid-cli via npm...");
    let _ = std::process::Command::new("bash")
        .args([
            "-c",
            &format!(
                "[ -s \"{nvm_dir}/nvm.sh\" ] && . \"{nvm_dir}/nvm.sh\"; npm install -g tree-sitter-cli @mermaid-js/mermaid-cli"
            ),
        ])
        .status();
}

fn install_lazygit(ctx: &Context, inst: &Installer) {
    if have("lazygit") {
        inst.log("OK (already installed): lazygit");
        return;
    }
    let home = ctx.home.to_string_lossy();
    inst.log("Installing lazygit (latest release)...");
    inst.run(&format!(
        "LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '\"tag_name\": *\"v\\K[^\"]*') &&     curl -fLo /tmp/lazygit.tar.gz \"https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${{LAZYGIT_VERSION}}_linux_x86_64.tar.gz\" &&     tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit &&     mkdir -p '{home}/.local/bin' &&     install /tmp/lazygit '{home}/.local/bin/lazygit' &&     rm -f /tmp/lazygit.tar.gz /tmp/lazygit"
    ));
}

fn install_lazydocker(inst: &Installer) {
    if have("lazydocker") {
        inst.log("OK (already installed): lazydocker");
        return;
    }
    inst.log("Installing lazydocker (official install script)...");
    inst.run("curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash");
}

fn file_nonempty(p: &str) -> bool {
    std::fs::metadata(p).map(|m| m.len() > 0).unwrap_or(false)
}
