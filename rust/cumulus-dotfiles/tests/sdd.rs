//! Integration tests for cumulus-sdd command.

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
        .output()
        .expect("run binary")
}

#[test]
fn sdd_help_prints_usage() {
    let out = run(env!("CARGO_BIN_EXE_cumulus-sdd"), &["--help"]);
    assert_eq!(out.status.code(), Some(0));
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(stdout.contains("token-efficient spec-driven development"));
}

#[test]
fn umbrella_dispatches_sdd_help() {
    let out = run(env!("CARGO_BIN_EXE_cumulus"), &["sdd", "--help"]);
    assert_eq!(out.status.code(), Some(0));
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(stdout.contains("token-efficient spec-driven development"));
}

#[test]
fn sdd_verify_runs_on_fixture() {
    let out = run(env!("CARGO_BIN_EXE_cumulus"), &["sdd", "verify"]);
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(stdout.contains("Verifying specs in"));
}
