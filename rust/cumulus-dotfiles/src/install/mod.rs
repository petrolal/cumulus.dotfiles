//! Shared support for the `install-*` commands: dry-run-aware command
//! execution, per-tag logging, argument parsing, and package-manager
//! detection. Ports the common `log`/`run`/arg-parse boilerplate that every
//! `scripts/install-*.sh` repeated.

pub mod apps;
pub mod browser;
pub mod deploy;
pub mod devops;
pub mod fonts;
pub mod nvim;
pub mod nvim_deps;
pub mod sdkman;
pub mod zsh;

use crate::error::{Error, Result};
use std::process::Command;

/// A dry-run-aware executor bound to a log tag (e.g. `fonts`, `devops`).
pub struct Installer {
    tag: &'static str,
    dry_run: bool,
}

impl Installer {
    pub fn new(tag: &'static str, dry_run: bool) -> Installer {
        Installer { tag, dry_run }
    }

    pub fn dry_run(&self) -> bool {
        self.dry_run
    }

    /// Print a blue `[tag] msg` line (matches the shell `log` helper).
    pub fn log(&self, msg: &str) {
        println!("\x1b[1;34m[{}]\x1b[0m {msg}", self.tag);
    }

    /// Run a shell command string. In dry-run, echo `+ <cmd>` and succeed;
    /// otherwise execute via `sh -c` (mirroring the shell `run`/`eval`).
    /// Returns whether the command succeeded.
    pub fn run(&self, cmd: &str) -> bool {
        if self.dry_run {
            println!("+ {cmd}");
            return true;
        }
        Command::new("sh")
            .args(["-c", cmd])
            .status()
            .map(|s| s.success())
            .unwrap_or(false)
    }

    /// Run an argv directly. In dry-run, echo `+ arg1 arg2 ...` with shell
    /// quoting (mirrors install-nvim's `run_cmd` using `printf ' %q'`).
    pub fn run_argv(&self, argv: &[&str]) -> bool {
        if self.dry_run {
            let mut line = String::from("+");
            for a in argv {
                line.push(' ');
                line.push_str(&shell_quote(a));
            }
            println!("{line}");
            return true;
        }
        match argv.split_first() {
            Some((prog, rest)) => Command::new(prog)
                .args(rest)
                .status()
                .map(|s| s.success())
                .unwrap_or(false),
            None => false,
        }
    }
}

/// Capture the trimmed stdout of `sh -c cmd` (for version banners embedded in
/// log lines, e.g. `$(docker --version)`).
pub fn sh_capture(cmd: &str) -> String {
    Command::new("sh")
        .args(["-c", cmd])
        .output()
        .ok()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim_end().to_string())
        .unwrap_or_default()
}

/// Whether a binary is resolvable on `PATH` (mirrors `command -v`).
pub fn have(bin: &str) -> bool {
    crate::util::command_exists(bin)
}

/// Standard `--dry-run` / `-h|--help` parsing shared by most installers.
/// Prints `help` and signals early-exit via `Ok(None)` on help.
pub fn parse_dry_run(args: &[String], help: &str) -> Result<Option<bool>> {
    let mut dry_run = false;
    for arg in args {
        match arg.as_str() {
            "--dry-run" => dry_run = true,
            "-h" | "--help" => {
                print!("{help}");
                return Ok(None);
            }
            other => {
                eprintln!("Unknown option: {other}");
                return Err(Error::with_code("", 1));
            }
        }
    }
    Ok(Some(dry_run))
}

/// bash `printf %q`-style quoting for the safe character set; single-quote
/// anything else. Sufficient for the URLs/paths the installers echo.
pub fn shell_quote(s: &str) -> String {
    let safe = !s.is_empty()
        && s.bytes()
            .all(|b| b.is_ascii_alphanumeric() || b"_./:=@%+-,".contains(&b));
    if safe {
        s.to_string()
    } else {
        format!("'{}'", s.replace('\'', r"'\''"))
    }
}
