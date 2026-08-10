//! `cumulus-install-sdkman` — install SDKMAN and the JVM toolchain. Ports
//! `install-sdkman.sh`.

use super::{parse_dry_run, Installer};
use crate::context::Context;
use crate::error::Result;
use std::io::{IsTerminal, Write};
use std::process::{Command, Stdio};

const HELP: &str = "\
install-sdkman.sh — install SDKMAN and the JVM toolchain it manages
(Java, Kotlin, Maven, Gradle).

Usage:
  cumulus-install-sdkman            # install sdkman + kotlin/maven/gradle
  cumulus-install-sdkman --dry-run  # preview commands, change nothing
  JAVA_VERSION=<id> cumulus-install-sdkman   # install Java non-interactively
";

fn sdkman_dir(ctx: &Context) -> std::path::PathBuf {
    std::env::var_os("SDKMAN_DIR")
        .map(std::path::PathBuf::from)
        .unwrap_or_else(|| ctx.home.join(".sdkman"))
}

pub fn run(ctx: &Context, args: &[String]) -> Result<()> {
    let Some(dry_run) = parse_dry_run(args, HELP)? else {
        return Ok(());
    };
    let inst = Installer::new("sdkman", dry_run);
    if dry_run {
        inst.log("DRY RUN — no changes will be made");
    }

    let dir = sdkman_dir(ctx);
    install_sdkman(ctx, &inst, &dir);

    if dry_run {
        inst.log("+ sdk install java <version>  (interactive prompt, or $JAVA_VERSION)");
        inst.log("+ sdk install kotlin");
        inst.log("+ sdk install maven");
        inst.log("+ sdk install gradle");
        return Ok(());
    }

    install_java(&inst, &dir);
    install_latest(&inst, &dir, "kotlin");
    install_latest(&inst, &dir, "maven");
    install_latest(&inst, &dir, "gradle");

    inst.log(
        "Done. Open a new shell (or 'source ~/.zshrc') to pick up java/kotlin/mvn/gradle on PATH.",
    );
    Ok(())
}

fn init_path(dir: &std::path::Path) -> std::path::PathBuf {
    dir.join("bin/sdkman-init.sh")
}

fn file_nonempty(p: &std::path::Path) -> bool {
    std::fs::metadata(p).map(|m| m.len() > 0).unwrap_or(false)
}

fn install_sdkman(ctx: &Context, inst: &Installer, dir: &std::path::Path) {
    if file_nonempty(&init_path(dir)) {
        inst.log(&format!(
            "OK (already installed): sdkman ({})",
            dir.display()
        ));
        return;
    }
    inst.log("Installing SDKMAN...");
    inst.run("curl -s \"https://get.sdkman.io\" | bash");
    if inst.dry_run() {
        return;
    }
    // The upstream installer appends its init snippet to ~/.zshrc, which is a
    // symlink into the tracked repo. Strip it back out.
    let zshrc = ctx.home.join(".zshrc");
    let has_snippet = std::fs::read_to_string(&zshrc)
        .map(|c| c.contains("FOR SDKMAN TO WORK"))
        .unwrap_or(false);
    if zshrc.is_file() && has_snippet {
        inst.log(&format!(
            "Removing SDKMAN's auto-appended snippet from {} (already handled by zsh_config/99-sdkman-cargo.zsh)...",
            zshrc.display()
        ));
        let _ = Command::new("sed")
            .args([
                "-i",
                "-e",
                r#"/^#.*FOR SDKMAN TO WORK/,/sdkman-init\.sh"$/d"#,
                "-e",
                "${/^$/d}",
            ])
            .arg(&zshrc)
            .status();
    }
}

/// `sdk install <args> < /dev/null` inside a login-ish shell that sources
/// sdkman-init.sh (empty stdin accepts the "set as default? (Y/n)" prompt).
fn sdk_install(dir: &std::path::Path, args: &[&str]) {
    let init = init_path(dir);
    let cmd = format!(". \"{}\" && sdk install {}", init.display(), args.join(" "));
    let _ = Command::new("bash")
        .args(["-c", &cmd])
        .stdin(Stdio::null())
        .status();
}

fn install_java(inst: &Installer, dir: &std::path::Path) {
    let mut java_version = std::env::var("JAVA_VERSION").unwrap_or_default();
    if java_version.is_empty() {
        if !std::io::stdin().is_terminal() {
            inst.log("No TTY and JAVA_VERSION not set — skipping Java.");
            inst.log("Re-run with JAVA_VERSION=<sdk-identifier> to install it non-interactively.");
            return;
        }
        inst.log("Available Java versions (the Identifier column is what to enter below):");
        let init = init_path(dir);
        let _ = Command::new("bash")
            .args(["-c", &format!(". \"{}\" && sdk list java", init.display())])
            .status();
        print!("Enter the Java version identifier to install (blank to skip): ");
        std::io::stdout().flush().ok();
        let mut line = String::new();
        std::io::stdin().read_line(&mut line).ok();
        java_version = line.trim().to_string();
        if java_version.is_empty() {
            inst.log("Skipping Java install.");
            return;
        }
    }
    inst.log(&format!("Installing Java {java_version} via sdkman..."));
    sdk_install(dir, &["java", &java_version]);
}

fn install_latest(inst: &Installer, dir: &std::path::Path, candidate: &str) {
    inst.log(&format!(
        "Installing latest stable {candidate} via sdkman..."
    ));
    sdk_install(dir, &[candidate]);
}
