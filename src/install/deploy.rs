//! `cumulus-install` / `cumulus deploy` — Rust port of `install.sh`.
//! Deploys cumulus.dotfiles onto a system (package installation, symlinking,
//! tool installation, theme application, and validation).

use crate::context::Context;
use crate::error::{Error, Result};
use crate::install::{apps, browser, devops, fonts, nvim, nvim_deps, sdkman, zsh, Installer};
use crate::theme;
use crate::util;
use crate::validate;
use std::fs;
use std::io::{self, IsTerminal, Write};
use std::path::Path;
use std::process::Command;

const APT_PACKAGES: &[&str] = &[
    "sway",
    "wofi",
    "waybar",
    "kitty",
    "grim",
    "slurp",
    "wl-clipboard",
    "brightnessctl",
    "playerctl",
    "swaylock",
    "swayidle",
    "wdisplays",
    "jq",
    "libnotify-bin",
    "blueman",
    "xkb-data",
    "openrgb",
    "qtwayland5",
];

const PACMAN_PACKAGES: &[&str] = &[
    "sway",
    "wofi",
    "waybar",
    "kitty",
    "grim",
    "slurp",
    "wl-clipboard",
    "brightnessctl",
    "playerctl",
    "swaylock",
    "swayidle",
    "wdisplays",
    "jq",
    "libnotify",
    "blueman",
    "yazi",
    "xkeyboard-config",
    "openrgb",
    "qt5-wayland",
    "qt6-wayland",
];

const AUR_PACKAGES: &[&str] = &["ttf-jetbrains-mono-nerd", "tuxedo-drivers-dkms"];

struct DeployOptions {
    dry_run: bool,
    do_packages: bool,
    do_zsh: bool,
    do_nvim: bool,
    do_apps: bool,
    do_devops: bool,
    do_browser: bool,
    do_sdkman: bool,
    do_all_tools: bool,
    do_validate: bool,
}

impl Default for DeployOptions {
    fn default() -> Self {
        Self {
            dry_run: false,
            do_packages: true,
            do_zsh: false,
            do_nvim: true,
            do_apps: false,
            do_devops: false,
            do_browser: false,
            do_sdkman: true,
            do_all_tools: false,
            do_validate: true,
        }
    }
}

pub fn run(ctx: &Context, args: &[String]) -> Result<()> {
    let mut opts = DeployOptions::default();

    for arg in args {
        match arg.as_str() {
            "--dry-run" => opts.dry_run = true,
            "--packages" => opts.do_packages = true,
            "--no-packages" => opts.do_packages = false,
            "--nvim" => opts.do_nvim = true,
            "--no-nvim" => opts.do_nvim = false,
            "--sdkman" => opts.do_sdkman = true,
            "--no-sdkman" => opts.do_sdkman = false,
            "--links-only" => {
                opts.do_packages = false;
                opts.do_nvim = false;
                opts.do_zsh = false;
                opts.do_apps = false;
                opts.do_devops = false;
                opts.do_browser = false;
                opts.do_sdkman = false;
                opts.do_all_tools = false;
            }
            "--zsh" => opts.do_zsh = true,
            "--apps" => opts.do_apps = true,
            "--devops" => opts.do_devops = true,
            "--browser" => opts.do_browser = true,
            "--all-tools" => opts.do_all_tools = true,
            "--no-validate" => opts.do_validate = false,
            "-h" | "--help" => {
                println!("{HELP_TEXT}");
                return Ok(());
            }
            other => {
                eprintln!("Unknown option: {other}");
                return Err(Error::with_code("", 1));
            }
        }
    }

    let inst = Installer::new("install", opts.dry_run);
    inst.log(&format!("Dotfiles repo: {}", ctx.dotfiles_dir.display()));
    if opts.dry_run {
        inst.log("DRY RUN — no changes will be made");
    }

    let timestamp = Command::new("date")
        .arg("+%Y%m%d_%H%M%S")
        .output()
        .ok()
        .filter(|o| o.status.success())
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_else(|| "fallback".to_string());
    let backup_dir = ctx.home.join(format!(".cumulus_backup/{timestamp}"));

    // 1. Packages
    if opts.do_packages {
        install_packages(&inst)?;
    }

    // 2. Symlinks
    let links: &[(&str, &str)] = &[
        ("zsh/.zshrc", ".zshrc"),
        ("zsh/zsh_config", ".config/cumulus/zsh_config"),
        ("config/sway", ".config/sway"),
        ("config/wofi", ".config/wofi"),
        ("config/waybar", ".config/waybar"),
        ("config/kitty", ".config/kitty"),
    ];

    for (src_rel, dst_rel) in links {
        link_one(ctx, &inst, src_rel, dst_rel, &backup_dir)?;
    }

    // 3. Binaries deployment to ~/.local/bin
    deploy_binaries(ctx, &inst)?;

    // 4. Fonts
    inst.log("Ensuring Nerd Font is installed (needed by kitty/waybar/wofi/sway configs)...");
    let font_args = if opts.dry_run {
        vec!["--dry-run".to_string()]
    } else {
        vec![]
    };
    fonts::run(ctx, &font_args)?;

    // 5. Theme
    inst.log("Applying theme (flavor + background mode)...");
    let theme_args = if opts.dry_run {
        vec!["apply".to_string(), "--dry-run".to_string()]
    } else {
        vec!["apply".to_string()]
    };
    let _ = theme::run(ctx, &theme_args);

    // 6. Additional tool installers
    let sub_args = if opts.dry_run {
        vec!["--dry-run".to_string()]
    } else {
        vec![]
    };

    if opts.do_all_tools {
        zsh::run(ctx, &sub_args)?;
        nvim_deps::run(ctx, &sub_args)?;
        let mut nvim_flags = sub_args.clone();
        if !opts.do_validate {
            nvim_flags.push("--no-validate".to_string());
        }
        nvim::run(ctx, &nvim_flags)?;
        apps::run(ctx, &sub_args)?;
        devops::run(ctx, &sub_args)?;
        browser::run(ctx, &sub_args)?;
        sdkman::run(ctx, &sub_args)?;
    } else {
        if opts.do_zsh {
            zsh::run(ctx, &sub_args)?;
        }
        if opts.do_nvim {
            nvim_deps::run(ctx, &sub_args)?;
            let mut nvim_flags = sub_args.clone();
            if !opts.do_validate {
                nvim_flags.push("--no-validate".to_string());
            }
            nvim::run(ctx, &nvim_flags)?;
        }
        if opts.do_apps {
            apps::run(ctx, &sub_args)?;
        }
        if opts.do_devops {
            devops::run(ctx, &sub_args)?;
        }
        if opts.do_browser {
            browser::run(ctx, &sub_args)?;
        }
        if opts.do_sdkman {
            sdkman::run(ctx, &sub_args)?;
        }
    }

    inst.log(&format!(
        "Done. Backups (if any) saved under: {}",
        backup_dir.display()
    ));
    inst.log("Reload sway with: swaymsg reload  (or Mod+Shift+C)");
    inst.log("Reload zsh with:  source ~/.zshrc");

    // 7. Validation
    if !opts.dry_run && opts.do_validate {
        inst.log("Running validation checks...");
        println!();
        if let Err(e) = validate::run(ctx, &[]) {
            inst.log(&format!("Validation reported issues — {e}"));
        }
    }

    // Reboot prompt
    if !opts.dry_run {
        let is_tty = io::stdin().is_terminal();
        if is_tty {
            println!();
            print!("Reboot system now to apply kernel modules & device permissions? [y/N] ");
            let _ = io::stdout().flush();
            let mut answer = String::new();
            if io::stdin().read_line(&mut answer).is_ok() {
                let trimmed = answer.trim();
                if trimmed.eq_ignore_ascii_case("y") || trimmed.eq_ignore_ascii_case("yes") {
                    inst.log("Rebooting system...");
                    let _ = Command::new("sudo").arg("reboot").status();
                } else {
                    inst.log("Reboot skipped. Run 'sudo reboot' when ready.");
                }
            }
        } else {
            inst.log("Reboot recommended to apply kernel modules & permissions: sudo reboot");
        }
    }

    Ok(())
}

fn install_packages(inst: &Installer) -> Result<()> {
    if util::command_exists("apt") {
        inst.log("Installing required packages via apt (Debian/Ubuntu)...");
        inst.run(&format!(
            "sudo apt update && sudo apt install -y {}",
            APT_PACKAGES.join(" ")
        ));
        if util::command_exists("udevadm") {
            inst.run(
                "sudo udevadm control --reload-rules && sudo udevadm trigger 2>/dev/null || true",
            );
        }
    } else if util::command_exists("pacman") {
        inst.log("Installing required packages via pacman (Arch)...");
        inst.run(&format!(
            "sudo pacman -Syu --needed --noconfirm {}",
            PACMAN_PACKAGES.join(" ")
        ));
        if util::command_exists("yay") {
            inst.log("Installing AUR packages via yay...");
            inst.run(&format!(
                "yay -S --needed --noconfirm {}",
                AUR_PACKAGES.join(" ")
            ));
        } else if util::command_exists("paru") {
            inst.log("Installing AUR packages via paru...");
            inst.run(&format!(
                "paru -S --needed --noconfirm {}",
                AUR_PACKAGES.join(" ")
            ));
        } else {
            inst.log(&format!(
                "No AUR helper (yay/paru) found — skipping: {}",
                AUR_PACKAGES.join(" ")
            ));
            inst.log("Install an AUR helper or install these manually if you want the Nerd Font.");
        }
    } else {
        inst.log(&format!(
            "No supported package manager found (apt/pacman). Install manually: {}",
            APT_PACKAGES.join(" ")
        ));
        return Err(Error::with_code("", 1));
    }

    inst.run("sudo modprobe i2c-dev 2>/dev/null || true");
    Ok(())
}

fn link_one(
    ctx: &Context,
    inst: &Installer,
    src_rel: &str,
    dst_rel: &str,
    backup_dir: &Path,
) -> Result<()> {
    let src = ctx.dotfiles_dir.join(src_rel);
    let dst = ctx.home.join(dst_rel);

    if !src.exists() {
        inst.log(&format!("SKIP (missing in repo): {src_rel}"));
        return Ok(());
    }

    if let Some(parent) = dst.parent() {
        if !inst.dry_run() {
            fs::create_dir_all(parent)?;
        }
    }

    let is_symlink = fs::symlink_metadata(&dst)
        .map(|m| m.file_type().is_symlink())
        .unwrap_or(false);

    if is_symlink {
        if let Ok(real_dst) = fs::canonicalize(&dst) {
            if let Ok(real_src) = fs::canonicalize(&src) {
                if real_dst == real_src {
                    inst.log(&format!("OK (already linked): {}", dst.display()));
                    return Ok(());
                }
            }
        }
        inst.log(&format!("Replacing existing symlink: {}", dst.display()));
        if !inst.dry_run() {
            let _ = fs::remove_file(&dst);
        } else {
            println!("+ rm -f '{}'", dst.display());
        }
    } else if dst.exists() {
        let backup_target = backup_dir.join(dst_rel);
        inst.log(&format!(
            "Backing up existing {} -> {}",
            dst.display(),
            backup_target.display()
        ));
        if !inst.dry_run() {
            if let Some(p) = backup_target.parent() {
                fs::create_dir_all(p)?;
            }
            fs::rename(&dst, &backup_target)?;
        } else {
            println!("+ mkdir -p '{}'", backup_target.parent().unwrap().display());
            println!("+ mv '{}' '{}'", dst.display(), backup_target.display());
        }
    }

    inst.log(&format!("Linking {} -> {}", dst.display(), src.display()));
    if !inst.dry_run() {
        std::os::unix::fs::symlink(&src, &dst)?;
    } else {
        println!("+ ln -s '{}' '{}'", src.display(), dst.display());
    }

    Ok(())
}

fn deploy_binaries(ctx: &Context, inst: &Installer) -> Result<()> {
    let bin_dir = ctx.home.join(".local/bin");
    if !inst.dry_run() {
        fs::create_dir_all(&bin_dir)?;
    }

    if util::command_exists("cargo") {
        inst.log("Building & deploying cumulus Rust binaries via cargo...");
        if !inst.dry_run() {
            let cargo_toml = ctx.dotfiles_dir.join("Cargo.toml");
            let _ = Command::new("cargo")
                .args([
                    "build",
                    "--release",
                    "--manifest-path",
                    &cargo_toml.to_string_lossy(),
                    "--quiet",
                ])
                .status();
            let release_dir = ctx.dotfiles_dir.join("target/release");
            if let Ok(entries) = fs::read_dir(&release_dir) {
                for entry in entries.flatten() {
                    let path = entry.path();
                    let name = path
                        .file_name()
                        .and_then(|n| n.to_str())
                        .unwrap_or_default();
                    if name.starts_with("cumulus") && !name.ends_with(".d") && path.is_file() {
                        let dst = bin_dir.join(name);
                        let _ = fs::copy(&path, &dst);
                    }
                }
            }
        } else {
            println!(
                "+ cargo build --release --manifest-path '{}/Cargo.toml'",
                ctx.dotfiles_dir.display()
            );
            println!(
                "+ cp -f '{}/target/release/cumulus*' '{}/'",
                ctx.dotfiles_dir.display(),
                bin_dir.display()
            );
        }
    }
    Ok(())
}

const HELP_TEXT: &str = "\
cumulus-install — deploy cumulus.dotfiles onto a machine.

Usage:
  cumulus install [options]
  cumulus-install [options]

Options:
  --dry-run      show what would happen, change nothing
  --packages     install required packages via apt/pacman (default)
  --no-packages  skip package installation
  --links-only   symlink configs only (no packages or tool installations)
  --nvim         deploy Neovim & dependencies (default)
  --no-nvim      skip Neovim deployment
  --sdkman       install SDKMAN! & JVM tooling (default)
  --no-sdkman    skip SDKMAN! deployment
  --zsh          also run install-zsh
  --apps         also run install-apps
  --devops       also run install-devops
  --browser      also run install-browser
  --all-tools    run every tool installer
  --no-validate  skip the final health check run
  -h, --help     show this help text
";
