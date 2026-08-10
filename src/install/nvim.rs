//! `cumulus-install-nvim` — clone/deploy the Cumulus Neovim config. Ports
//! `install-nvim.sh`.

use super::{have, shell_quote, Installer};
use crate::context::Context;
use crate::error::{Error, Result};
use std::path::Path;
use std::process::Command;

const HELP: &str = "\
install-nvim.sh — install and deploy the canonical Cumulus Neovim config.

The dependency/toolchain installer is cumulus-install-nvim-deps. This
command owns only the config repository and its ~/.config/nvim symlink.

Usage:
  cumulus-install-nvim                # clone/update and deploy Cumulus Neovim
  cumulus-install-nvim --dry-run      # preview without changing anything
  cumulus-install-nvim --no-validate  # skip headless Neovim validation
";

fn die(inst: &Installer, msg: &str) -> Error {
    eprintln!("\x1b[1;31m[nvim] error:\x1b[0m {msg}");
    let _ = inst;
    Error::with_code("", 1)
}

pub fn run(ctx: &Context, args: &[String]) -> Result<()> {
    let mut dry_run = false;
    let mut do_validate = true;
    for arg in args {
        match arg.as_str() {
            "--dry-run" => dry_run = true,
            "--no-validate" => do_validate = false,
            "-h" | "--help" => {
                print!("{HELP}");
                return Ok(());
            }
            other => {
                eprintln!("Unknown option: {other}");
                return Err(Error::with_code("", 1));
            }
        }
    }
    let inst = Installer::new("nvim", dry_run);

    let repo_url = std::env::var("CUMULUS_NVIM_REPO_URL")
        .unwrap_or_else(|_| "https://github.com/petrolal/cumulus.nvim.git".to_string());
    let repo_dir = std::env::var("CUMULUS_NVIM_DIR")
        .map(std::path::PathBuf::from)
        .unwrap_or_else(|_| ctx.home.join("cumulus.nvim"));

    if dry_run {
        inst.log("DRY RUN — no changes will be made");
    }
    inst.log(&format!("Repository: {}", repo_dir.display()));
    clone_or_update(&inst, &repo_url, &repo_dir)?;
    deploy_config(ctx, &inst, &repo_dir)?;
    validate_config(&inst, dry_run, do_validate)?;
    inst.log("Cumulus Neovim installation complete.");
    Ok(())
}

fn normalize_url(url: &str) -> String {
    let mut u = url.strip_suffix(".git").unwrap_or(url).to_string();
    u = u.strip_prefix("https://").unwrap_or(&u).to_string();
    u = u.strip_prefix("http://").unwrap_or(&u).to_string();
    u = u.strip_prefix("git@").unwrap_or(&u).to_string();
    u.replacen(':', "/", 1)
}

fn clone_or_update(inst: &Installer, repo_url: &str, repo_dir: &Path) -> Result<()> {
    if repo_dir.exists() && !repo_dir.join(".git").is_dir() {
        return Err(die(
            inst,
            &format!(
                "Cumulus Neovim path exists but is not a git checkout: {}",
                repo_dir.display()
            ),
        ));
    }

    if !repo_dir.exists() {
        inst.log(&format!("Cloning Cumulus Neovim from {repo_url}"));
        inst.run_argv(&["git", "clone", repo_url, &repo_dir.to_string_lossy()]);
        return Ok(());
    }

    let origin = super::sh_capture(&format!(
        "git -C {} remote get-url origin 2>/dev/null || true",
        shell_quote(&repo_dir.to_string_lossy())
    ));
    if normalize_url(&origin) != normalize_url(repo_url) {
        if inst.dry_run() {
            inst.log(&format!("DRY RUN: would refuse origin mismatch: {origin}"));
            return Ok(());
        }
        return Err(die(
            inst,
            &format!("Cumulus Neovim origin mismatch: {origin}"),
        ));
    }

    let porcelain = super::sh_capture(&format!(
        "git -C {} status --porcelain",
        shell_quote(&repo_dir.to_string_lossy())
    ));
    if !porcelain.trim().is_empty() {
        inst.log("WARN: Cumulus Neovim checkout has local changes; skipping git pull.");
    } else {
        inst.log("Updating Cumulus Neovim with fast-forward-only pull");
        inst.run_argv(&[
            "git",
            "-C",
            &repo_dir.to_string_lossy(),
            "pull",
            "--ff-only",
        ]);
    }
    Ok(())
}

fn deploy_config(ctx: &Context, inst: &Installer, repo_dir: &Path) -> Result<()> {
    let config_dir = ctx.home.join(".config/nvim");
    if !inst.dry_run() {
        if let Some(parent) = config_dir.parent() {
            std::fs::create_dir_all(parent)?;
        }
    }

    if crate::util::is_symlink(&config_dir) && realpath(&config_dir) == realpath(repo_dir) {
        inst.log(&format!("OK (already linked): {}", config_dir.display()));
        return Ok(());
    }

    if crate::util::is_symlink(&config_dir) || config_dir.exists() {
        let backup_dir = if inst.dry_run() {
            format!(
                "{}/.cumulus_backup/{}.XXXXXX",
                ctx.home.display(),
                date("+%Y%m%d_%H%M%S")
            )
        } else {
            std::fs::create_dir_all(ctx.home.join(".cumulus_backup"))?;
            super::sh_capture(&format!(
                "mktemp -d {}/.cumulus_backup/{}.XXXXXX",
                shell_quote(&ctx.home.to_string_lossy()),
                date("+%Y%m%d_%H%M%S")
            ))
        };
        inst.log(&format!(
            "Backing up existing Neovim config -> {backup_dir}/.config/nvim"
        ));
        inst.run_argv(&["mkdir", "-p", &format!("{backup_dir}/.config")]);
        inst.run_argv(&[
            "mv",
            &config_dir.to_string_lossy(),
            &format!("{backup_dir}/.config/nvim"),
        ]);
    }

    inst.log(&format!(
        "Linking {} -> {}",
        config_dir.display(),
        repo_dir.display()
    ));
    inst.run_argv(&[
        "ln",
        "-s",
        &repo_dir.to_string_lossy(),
        &config_dir.to_string_lossy(),
    ]);
    Ok(())
}

fn validate_config(inst: &Installer, dry_run: bool, do_validate: bool) -> Result<()> {
    if dry_run || !do_validate {
        return Ok(());
    }
    if !have("nvim") {
        inst.log("WARN: nvim is not installed; skipping headless validation.");
        return Ok(());
    }
    inst.log("Running Neovim headless validation...");
    let ok = Command::new("nvim")
        .args(["--headless", "+Lazy check", "+qa"])
        .status()
        .map(|s| s.success())
        .unwrap_or(false);
    if !ok {
        return Err(die(
            inst,
            "Neovim validation failed; inspect the configuration before continuing.",
        ));
    }
    Ok(())
}

fn realpath(p: &Path) -> std::path::PathBuf {
    std::fs::canonicalize(p).unwrap_or_else(|_| p.to_path_buf())
}

fn date(fmt: &str) -> String {
    super::sh_capture(&format!("date {fmt}"))
}
