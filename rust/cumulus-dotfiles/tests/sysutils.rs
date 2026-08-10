//! Integration tests for the session-utility commands. lock/idle exec real
//! Wayland tools, so we only assert the safe, deterministic paths: the
//! screenshot argument contract and umbrella dispatch wiring.

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
        // Empty PATH so no real screenshot tools are ever invoked.
        .env("PATH", "")
        .output()
        .expect("run binary")
}

#[test]
fn screenshot_rejects_unknown_mode() {
    let out = run(env!("CARGO_BIN_EXE_cumulus-screenshot"), &["bogus"]);
    assert_eq!(out.status.code(), Some(1));
    let stderr = String::from_utf8_lossy(&out.stderr);
    assert!(
        stderr.contains("full|region|window"),
        "stderr was: {stderr}"
    );
}

#[test]
fn umbrella_dispatches_screenshot_usage() {
    let out = run(env!("CARGO_BIN_EXE_cumulus"), &["screenshot", "bogus"]);
    assert_eq!(out.status.code(), Some(1));
}
