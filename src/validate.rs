//! `cumulus-validate` — read-only health check of a deployed cumulus.dotfiles.
//!
//! Ports `validate.sh`. Prints OK / WARN / FAIL lines per check and exits
//! non-zero if any FAIL was recorded (WARN never affects the exit code). Never
//! modifies anything.

use crate::collate;
use crate::context::Context;
use crate::error::{Error, Result};
use std::path::{Path, PathBuf};
use std::process::Command;

const HELP: &str = "\
validate.sh — sanity-check that this cumulus.dotfiles repo is correctly deployed.

Meant to be run at the end of install.sh (automatic), or any time by hand
to check the current state of the machine. Never modifies anything —
read-only checks, each printed as OK / WARN / FAIL.

  OK   — expected state confirmed.
  WARN — optional/tool-dependent thing missing (not necessarily a problem,
         e.g. a devops tool you never asked to install).
  FAIL — something that should be true given what's installed isn't
         (broken symlink, invalid config, etc).

Exit code is non-zero if any FAIL was recorded (WARN doesn't affect it).

Usage:
  cumulus-validate          # run all checks, human-readable output
  cumulus-validate --quiet  # only print WARN/FAIL lines (for cron/CI use)
";

struct Report {
    quiet: bool,
    fails: u32,
    warns: u32,
}

impl Report {
    fn ok(&self, msg: &str) {
        if !self.quiet {
            println!("  \x1b[1;32mOK\x1b[0m   {msg}");
        }
    }
    fn warn(&mut self, msg: &str) {
        self.warns += 1;
        println!("  \x1b[1;33mWARN\x1b[0m {msg}");
    }
    fn fail(&mut self, msg: &str) {
        self.fails += 1;
        println!("  \x1b[1;31mFAIL\x1b[0m {msg}");
    }
    fn section(&self, name: &str) {
        if !self.quiet {
            println!("\x1b[1;34m==> {name}\x1b[0m");
        }
    }
}

/// `readlink -f`: canonicalize, falling back to the original path on failure.
fn realpath(p: &Path) -> PathBuf {
    std::fs::canonicalize(p).unwrap_or_else(|_| p.to_path_buf())
}

/// Run `timeout 5 <bin> <flag...> 2>&1 | head -1` for a version banner.
fn first_line(bin: &str, flag: &str) -> String {
    let script = format!("timeout 5 {bin} {flag} 2>&1 | head -1");
    Command::new("sh")
        .args(["-c", &script])
        .output()
        .ok()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim_end().to_string())
        .unwrap_or_default()
}

fn check_cmd(r: &mut Report, label: &str, bin: &str, flag: &str) {
    if crate::util::command_exists(bin) {
        r.ok(&format!("{label}: {}", first_line(bin, flag)));
    } else {
        r.warn(&format!(
            "{label} not found ({bin}) — install with the matching scripts/install-*.sh if you need it"
        ));
    }
}

fn check_link(r: &mut Report, ctx: &Context, src_rel: &str, dst_rel: &str) {
    let dst = ctx.home.join(dst_rel);
    let src = ctx.dotfiles_dir.join(src_rel);
    let is_symlink = crate::util::is_symlink(&dst);
    let exists = dst.exists() || is_symlink;
    if !exists {
        r.fail(&format!("{dst_rel} does not exist"));
    } else if !is_symlink {
        r.fail(&format!(
            "{dst_rel} exists but is not a symlink (real file/dir — install.sh would back it up before linking)"
        ));
    } else if realpath(&dst) != realpath(&src) {
        r.fail(&format!(
            "{dst_rel} is a symlink but points elsewhere: {}",
            realpath(&dst).display()
        ));
    } else {
        r.ok(&format!("{dst_rel} -> repo ({src_rel})"));
    }
}

/// `cumulus-validate [--quiet]`.
pub fn run(ctx: &Context, args: &[String]) -> Result<()> {
    let mut quiet = false;
    for arg in args {
        match arg.as_str() {
            "--quiet" => quiet = true,
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
    let mut r = Report {
        quiet,
        fails: 0,
        warns: 0,
    };

    // --- Symlinked configs ---
    r.section("Symlinked configs");
    check_link(&mut r, ctx, "zsh/.zshrc", ".zshrc");
    check_link(&mut r, ctx, "zsh/zsh_config", ".config/cumulus/zsh_config");
    check_link(&mut r, ctx, "config/sway", ".config/sway");
    check_link(&mut r, ctx, "config/wofi", ".config/wofi");
    check_link(&mut r, ctx, "config/waybar", ".config/waybar");
    check_link(&mut r, ctx, "config/kitty", ".config/kitty");

    // --- Scripts on PATH ---
    r.section("Scripts on PATH");
    let mut scripts: Vec<PathBuf> = std::fs::read_dir(ctx.dotfiles_dir.join("scripts"))
        .into_iter()
        .flatten()
        .flatten()
        .map(|e| e.path())
        .filter(|p| p.extension().map(|e| e == "sh").unwrap_or(false))
        .collect();
    collate::sort_paths(&mut scripts);
    for script in &scripts {
        let name = script.file_stem().and_then(|s| s.to_str()).unwrap_or("");
        let cmd = ctx.home.join(".local/bin").join(format!("cumulus-{name}"));
        if crate::util::is_symlink(&cmd) && realpath(&cmd) == realpath(script) {
            r.ok(&format!("cumulus-{name}"));
        } else {
            r.fail(&format!(
                "cumulus-{name} is missing or not linked to {}",
                script.display()
            ));
        }
    }
    if path_contains(&ctx.home.join(".local/bin")) {
        r.ok("$HOME/.local/bin is on $PATH");
    } else {
        r.warn("$HOME/.local/bin is not on $PATH in this shell — cumulus-* commands won't resolve");
    }

    // --- Sway ---
    r.section("Sway");
    if crate::util::command_exists("sway") {
        r.ok(&format!("sway: {}", first_line("sway", "--version")));
        let cfg = ctx.home.join(".config/sway/config");
        let out = Command::new("sh")
            .args([
                "-c",
                &format!(
                    "timeout 10 sway --validate -c {} 2>&1",
                    shell_quote(&cfg.to_string_lossy())
                ),
            ])
            .output();
        match out {
            Ok(o) if o.status.success() => r.ok("sway config validates"),
            Ok(o) => {
                r.fail("sway config failed validation:");
                for line in String::from_utf8_lossy(&o.stdout).lines() {
                    println!("         {line}");
                }
            }
            Err(_) => r.fail("sway config failed validation:"),
        }
    } else {
        r.warn("sway not found — run ./install.sh --packages");
    }
    check_cmd(&mut r, "wofi", "wofi", "--version");
    check_cmd(&mut r, "waybar", "waybar", "-v");
    check_cmd(&mut r, "kitty", "kitty", "--version");
    check_cmd(&mut r, "blueman-applet", "blueman-applet", "-h");
    check_cmd(&mut r, "yazi", "yazi", "--version");

    // --- Zsh ---
    r.section("Zsh");
    check_zsh(&mut r, ctx);

    // --- Fonts ---
    r.section("Fonts");
    if jetbrains_font_installed() {
        r.ok("JetBrainsMono Nerd Font installed");
    } else {
        r.warn("JetBrainsMono Nerd Font not found — run cumulus-install-fonts (or ./install.sh)");
    }

    // --- Neovim ---
    r.section("Neovim");
    check_cmd(&mut r, "neovim", "nvim", "--version");
    check_cmd(&mut r, "luarocks", "luarocks", "--version");
    check_cmd(&mut r, "ripgrep", "rg", "--version");
    if crate::util::command_exists("fd") || crate::util::command_exists("fdfind") {
        r.ok("fd/fdfind found");
    } else {
        r.warn("fd not found — run cumulus-install-nvim-deps");
    }
    check_cmd(&mut r, "tree-sitter-cli", "tree-sitter", "--version");
    check_cmd(&mut r, "lazygit", "lazygit", "--version");
    check_cmd(&mut r, "lazydocker", "lazydocker", "--version");
    check_cmd(&mut r, "node", "node", "--version");
    check_cmd(&mut r, "npm", "npm", "--version");

    // --- DevOps tools ---
    r.section("DevOps tools");
    check_cmd(&mut r, "docker", "docker", "--version");
    if crate::util::command_exists("docker") {
        if user_in_docker_group() {
            r.ok(&format!("{} is in the docker group", username()));
        } else {
            r.warn(&format!(
                "{} is not in the docker group — run cumulus-install-devops (re-login required after)",
                username()
            ));
        }
    }
    check_cmd(&mut r, "terraform", "terraform", "version");
    check_cmd(&mut r, "ansible", "ansible", "--version");

    // --- SDKMAN toolchain ---
    r.section("SDKMAN toolchain");
    let sdk_init = ctx.home.join(".sdkman/bin/sdkman-init.sh");
    if file_nonempty(&sdk_init) {
        r.ok(&format!(
            "sdkman: installed ({})",
            ctx.home.join(".sdkman").display()
        ));
    } else {
        r.warn("sdkman not found — install with cumulus-install-sdkman if you need Java/Kotlin/Maven/Gradle");
    }
    check_cmd(&mut r, "java", "java", "-version");
    check_cmd(&mut r, "kotlin", "kotlin", "-version");
    check_cmd(&mut r, "maven", "mvn", "-version");
    if crate::util::command_exists("gradle") {
        let line = Command::new("sh")
            .args(["-c", "timeout 5 gradle -version 2>&1 | grep '^Gradle '"])
            .output()
            .ok()
            .map(|o| String::from_utf8_lossy(&o.stdout).trim_end().to_string())
            .unwrap_or_default();
        r.ok(&format!("gradle: {line}"));
    } else {
        r.warn("gradle not found (gradle) — install with the matching scripts/install-*.sh if you need it");
    }

    // --- Summary ---
    r.section("Summary");
    if r.fails == 0 && r.warns == 0 {
        println!("Everything checks out. ✅");
    } else if r.fails == 0 {
        println!(
            "No failures, {} optional item(s) not installed (see WARN lines above).",
            r.warns
        );
    } else {
        println!("{} check(s) FAILED, {} WARN — see above.", r.fails, r.warns);
    }

    if r.fails > 0 {
        Err(Error::with_code("", 1))
    } else {
        Ok(())
    }
}

fn check_zsh(r: &mut Report, ctx: &Context) {
    if !crate::util::command_exists("zsh") {
        r.warn("zsh not found — run cumulus-install-zsh");
        return;
    }
    r.ok(&format!("zsh: {}", first_line("zsh", "--version")));

    // Default login shell vs zsh (compare canonicalized paths).
    let login = std::env::var("LOGNAME")
        .or_else(|_| std::env::var("USER"))
        .unwrap_or_default();
    let user_shell = Command::new("getent")
        .args(["passwd", &login])
        .output()
        .ok()
        .filter(|o| o.status.success())
        .and_then(|o| {
            String::from_utf8_lossy(&o.stdout)
                .lines()
                .next()
                .and_then(|l| l.rsplit(':').next())
                .map(str::to_string)
        })
        .or_else(|| std::env::var("SHELL").ok())
        .unwrap_or_default();
    let zsh_path = which("zsh").unwrap_or_default();
    let real_user_shell = realpath(Path::new(&user_shell));
    let real_zsh = realpath(Path::new(&zsh_path));
    if !user_shell.is_empty() && !zsh_path.is_empty() && real_user_shell == real_zsh {
        r.ok(&format!("zsh is the default login shell ({user_shell})"));
    } else {
        let shown = if user_shell.is_empty() {
            std::env::var("SHELL").unwrap_or_default()
        } else {
            user_shell.clone()
        };
        r.warn(&format!(
            "default login shell is {shown}, not zsh — run cumulus-install-zsh (falls back to usermod on AD/LDAP accounts where chsh fails)"
        ));
    }

    if ctx.home.join(".oh-my-zsh").is_dir() {
        r.ok("oh-my-zsh installed");
    } else {
        r.warn("oh-my-zsh not installed — run cumulus-install-zsh");
    }

    let out = Command::new("sh")
        .args([
            "-c",
            "timeout 10 zsh +m -i -c 'echo \"$ZSH_THEME|$EDITOR\"' 2>/tmp/zsh-validate.cumulus",
        ])
        .output();
    match out {
        Ok(o) if o.status.success() => {
            let s = String::from_utf8_lossy(&o.stdout);
            let s = s.trim();
            let (theme, editor) = s.split_once('|').unwrap_or((s, ""));
            r.ok(&format!(
                "interactive zsh loads with no errors (ZSH_THEME={theme}, EDITOR={editor})"
            ));
            let _ = std::fs::remove_file("/tmp/zsh-validate.cumulus");
        }
        Ok(o) => {
            let code = o.status.code().unwrap_or(-1);
            r.fail(&format!(
                "interactive zsh startup produced an error (exit {code}):"
            ));
            if let Ok(err) = std::fs::read_to_string("/tmp/zsh-validate.cumulus") {
                for line in err.lines() {
                    println!("         {line}");
                }
            }
            let _ = std::fs::remove_file("/tmp/zsh-validate.cumulus");
        }
        Err(_) => r.fail("interactive zsh startup produced an error:"),
    }
}

fn jetbrains_font_installed() -> bool {
    Command::new("fc-list")
        .output()
        .ok()
        .filter(|o| o.status.success())
        .map(|o| {
            String::from_utf8_lossy(&o.stdout)
                .to_lowercase()
                .contains("jetbrainsmono nerd font")
        })
        .unwrap_or(false)
}

fn user_in_docker_group() -> bool {
    Command::new("id")
        .args(["-nG", &username()])
        .output()
        .ok()
        .filter(|o| o.status.success())
        .map(|o| {
            String::from_utf8_lossy(&o.stdout)
                .split_whitespace()
                .any(|g| g == "docker")
        })
        .unwrap_or(false)
}

fn username() -> String {
    std::env::var("USER")
        .ok()
        .or_else(crate::util::current_username)
        .unwrap_or_default()
}

fn file_nonempty(p: &Path) -> bool {
    std::fs::metadata(p).map(|m| m.len() > 0).unwrap_or(false)
}

fn which(bin: &str) -> Option<String> {
    let path = std::env::var_os("PATH")?;
    std::env::split_paths(&path)
        .map(|d| d.join(bin))
        .find(|p| crate::util::is_executable(p))
        .map(|p| p.to_string_lossy().into_owned())
}

fn path_contains(dir: &Path) -> bool {
    let Some(path) = std::env::var_os("PATH") else {
        return false;
    };
    std::env::split_paths(&path).any(|d| d == dir)
}

fn shell_quote(s: &str) -> String {
    format!("'{}'", s.replace('\'', r"'\''"))
}
