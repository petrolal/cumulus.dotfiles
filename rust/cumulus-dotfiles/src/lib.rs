//! cumulus-dotfiles — Rust tooling for the cumulus.dotfiles desktop.
//!
//! All logic lives in this library; each installed `cumulus-*` command is a
//! thin multi-call binary that dispatches on its own name via [`dispatch`].
//! `cargo install cumulus-dotfiles` installs the whole suite into
//! `~/.cargo/bin`.

pub mod collate;
pub mod context;
pub mod error;
pub mod install;
pub mod maintenance;
pub mod refresh;
pub mod sysutils;
pub mod theme;
pub mod util;
pub mod validate;

use context::Context;
use error::Result;
use std::path::Path;
use std::process::ExitCode;

/// Map a resolved command name to its handler.
fn run_command(name: &str, args: &[String]) -> Result<()> {
    let ctx = Context::discover()?;
    match name {
        "theme" => theme::run(&ctx, args),
        "runtime-refresh" => refresh::run_runtime_refresh(&ctx),
        "os-colorscheme" => refresh::run_os_colorscheme(&ctx),
        "rgb-theme" => refresh::run_rgb_theme(&ctx, args),
        "lock" => sysutils::run_lock(&ctx),
        "idle" => sysutils::run_idle(&ctx),
        "screenshot" => sysutils::run_screenshot(&ctx, args),
        "validate" => validate::run(&ctx, args),
        "backup" => maintenance::run_backup(&ctx, args),
        "restore" => maintenance::run_restore(&ctx, args),
        "update" => maintenance::run_update(&ctx, args),
        "install-fonts" => install::fonts::run(&ctx, args),
        "install-apps" => install::apps::run(&ctx, args),
        "install-browser" => install::browser::run(&ctx, args),
        "install-devops" => install::devops::run(&ctx, args),
        "install-zsh" => install::zsh::run(&ctx, args),
        "install-sdkman" => install::sdkman::run(&ctx, args),
        "install-nvim" => install::nvim::run(&ctx, args),
        "install-nvim-deps" => install::nvim_deps::run(&ctx, args),
        other => Err(error::Error::new(format!(
            "unknown command '{other}' (known: theme, runtime-refresh, os-colorscheme, rgb-theme, lock, idle, screenshot, validate, backup, restore, update, install-fonts, install-apps, install-browser, install-devops, install-zsh, install-sdkman, install-nvim, install-nvim-deps)"
        ))),
    }
}

/// Resolve the command from `argv[0]` (`cumulus-<name>`) or, when invoked as
/// the umbrella `cumulus`, from the first argument.
pub fn dispatch() -> ExitCode {
    let args: Vec<String> = std::env::args().collect();
    let prog = args
        .first()
        .map(|p| {
            Path::new(p)
                .file_name()
                .and_then(|s| s.to_str())
                .unwrap_or(p)
                .to_string()
        })
        .unwrap_or_default();

    let (name, rest): (String, Vec<String>) = if let Some(sub) = prog.strip_prefix("cumulus-") {
        // Invoked via a `cumulus-<name>` symlink/binary.
        (sub.to_string(), args[1..].to_vec())
    } else {
        // Invoked as the umbrella `cumulus <command> ...`.
        match args.get(1) {
            Some(cmd) if !cmd.starts_with('-') => (cmd.clone(), args[2..].to_vec()),
            _ => {
                print!("{UMBRELLA_HELP}");
                return ExitCode::SUCCESS;
            }
        }
    };

    match run_command(&name, &rest) {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            if !e.to_string().is_empty() {
                eprintln!("\x1b[1;31m[cumulus] error:\x1b[0m {e}");
            }
            ExitCode::from(e.code())
        }
    }
}

const UMBRELLA_HELP: &str = "\
cumulus — tooling for the cumulus.dotfiles Sway/Wayland desktop.

Usage:
  cumulus <command> [args...]
  cumulus-<command> [args...]      (installed alias)

Commands:
  theme            select a desktop flavor + background mode and apply it live
  runtime-refresh  refresh running apps (sway/waybar/kitty/wofi/neovim/os/rgb)
  os-colorscheme   sync the GNOME/GTK color-scheme setting
  rgb-theme        sync hardware RGB lighting with the active theme color
  lock             lock the screen (swaylock) styled to the active theme
  idle             run the swayidle daemon (auto-lock, dpms, suspend)
  screenshot       capture a screenshot (full|region|window)
  validate         read-only health check of the deployed setup
  backup           snapshot managed configs to a timestamped tarball
  restore          restore a snapshot created by backup
  update           git pull the dotfiles and re-run the installer
  install-fonts    install the JetBrainsMono Nerd Font
  install-apps     install core desktop apps (sway/waybar/kitty/etc.)
  install-browser  install a web browser (brave/chromium)
  install-devops   install devops tooling (docker/terraform/kubectl/etc.)
  install-zsh      install zsh + oh-my-zsh + plugins and set the shell
  install-sdkman   install SDKMAN! and JVM tooling
  install-nvim     install the Neovim config dependencies (deploy)
  install-nvim-deps install Neovim + its plugin ecosystem dependencies

Run `cumulus <command> --help` for command-specific usage.
";
