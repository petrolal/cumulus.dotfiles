//! Integration tests for `cumulus-validate`. The full run is environment
//! dependent, so we assert the deterministic contract: help, unknown-option
//! handling, quiet mode, section presence, and FAIL-driven exit codes against
//! isolated fixture repos/homes.

use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Output};

fn repo_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(2)
        .expect("repo root")
        .to_path_buf()
}

fn uniq() -> u128 {
    use std::time::{SystemTime, UNIX_EPOCH};
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_nanos()
}

fn copy_dir(src: &Path, dst: &Path) {
    fs::create_dir_all(dst).unwrap();
    for entry in fs::read_dir(src).unwrap() {
        let entry = entry.unwrap();
        let name = entry.file_name();
        if name == ".git" || name == "target" {
            continue;
        }
        let from = entry.path();
        let to = dst.join(&name);
        let ft = entry.file_type().unwrap();
        if ft.is_dir() {
            copy_dir(&from, &to);
        } else if ft.is_symlink() {
            if let Ok(target) = fs::read_link(&from) {
                let _ = std::os::unix::fs::symlink(target, &to);
            }
        } else {
            fs::copy(&from, &to).unwrap();
        }
    }
}

struct Sandbox {
    dir: PathBuf,
    repo: PathBuf,
    home: PathBuf,
}

impl Sandbox {
    fn new() -> Sandbox {
        let dir = std::env::temp_dir().join(format!(
            "cumulus-validate-{}-{}",
            std::process::id(),
            uniq()
        ));
        let repo = dir.join("repo");
        let home = dir.join("home");
        fs::create_dir_all(&home).unwrap();
        copy_dir(&repo_root(), &repo);
        Sandbox { dir, repo, home }
    }

    fn run(&self, args: &[&str]) -> Output {
        Command::new(env!("CARGO_BIN_EXE_cumulus-validate"))
            .args(args)
            .env("HOME", &self.home)
            .env("CUMULUS_DOTFILES_DIR", &self.repo)
            .output()
            .expect("run binary")
    }
}

impl Drop for Sandbox {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.dir);
    }
}

#[test]
fn help_prints_usage_and_exits_zero() {
    let sb = Sandbox::new();
    let out = sb.run(&["--help"]);
    assert!(out.status.success());
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(stdout.contains("read-only checks"), "stdout: {stdout}");
    assert!(stdout.contains("--quiet"), "stdout: {stdout}");
}

#[test]
fn unknown_option_errors() {
    let sb = Sandbox::new();
    let out = sb.run(&["--nope"]);
    assert_eq!(out.status.code(), Some(1));
    assert!(String::from_utf8_lossy(&out.stderr).contains("Unknown option: --nope"));
}

#[test]
fn missing_symlinks_are_reported_as_fail_and_exit_nonzero() {
    // A fresh HOME has none of the expected config symlinks -> FAILs -> exit 1.
    let sb = Sandbox::new();
    let out = sb.run(&["--quiet"]);
    assert_eq!(out.status.code(), Some(1));
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(stdout.contains("FAIL"), "expected FAIL lines: {stdout}");
    assert!(stdout.contains(".zshrc does not exist"), "stdout: {stdout}");
    // Quiet mode still prints the summary line.
    assert!(stdout.contains("check(s) FAILED"), "stdout: {stdout}");
}

#[test]
fn quiet_mode_suppresses_ok_and_section_lines() {
    let sb = Sandbox::new();
    let out = sb.run(&["--quiet"]);
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(
        !stdout.contains("==>"),
        "sections should be hidden: {stdout}"
    );
    assert!(
        !stdout.contains("\x1b[1;32mOK\x1b[0m"),
        "OK lines should be hidden in quiet mode"
    );
}

#[test]
fn non_quiet_run_emits_all_sections() {
    let sb = Sandbox::new();
    let out = sb.run(&[]);
    let stdout = String::from_utf8_lossy(&out.stdout);
    for section in [
        "Symlinked configs",
        "Scripts on PATH",
        "Sway",
        "Zsh",
        "Fonts",
        "Neovim",
        "DevOps tools",
        "SDKMAN toolchain",
        "Summary",
    ] {
        assert!(
            stdout.contains(section),
            "missing section {section}: {stdout}"
        );
    }
}
