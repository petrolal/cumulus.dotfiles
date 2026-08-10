//! Integration tests for pickers and autotiling commands.

use std::path::PathBuf;
use std::process::{Command, Output};

fn repo_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(2)
        .expect("repo root")
        .to_path_buf()
}

fn run(exe: &str, args: &[&str]) -> Output {
    Command::new(exe)
        .args(args)
        .env("CUMULUS_DOTFILES_DIR", repo_root())
        .env("PATH", "")
        .env("SWAYSOCK", "/nonexistent_socket")
        .output()
        .expect("run binary")
}

#[test]
fn autotiling_help_prints_description_and_exits_zero() {
    let out = run(env!("CARGO_BIN_EXE_cumulus-autotiling"), &["--help"]);
    assert_eq!(out.status.code(), Some(0));
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(stdout.contains("Fibonacci spiral autotiling"));
}

#[test]
fn autotiling_fails_gracefully_without_swaysock() {
    let out = run(env!("CARGO_BIN_EXE_cumulus-autotiling"), &[]);
    assert_eq!(out.status.code(), Some(1));
    let stderr = String::from_utf8_lossy(&out.stderr);
    assert!(stderr.contains("SWAYSOCK not available"));
}

#[test]
fn umbrella_dispatches_autotiling_help() {
    let out = run(env!("CARGO_BIN_EXE_cumulus"), &["autotiling", "--help"]);
    assert_eq!(out.status.code(), Some(0));
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(stdout.contains("Fibonacci spiral autotiling"));
}
