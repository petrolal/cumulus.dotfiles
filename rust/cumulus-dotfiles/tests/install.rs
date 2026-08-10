//! Integration tests for the `install-*` commands. These exercise only the
//! deterministic, side-effect-free paths: `--dry-run` echoes, `--help` text,
//! unknown-option handling, and the "no supported package manager" branch
//! (forced via an empty `PATH`). Real installs are never triggered.

use std::path::PathBuf;
use std::process::{Command, Output};

fn repo_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(2)
        .expect("repo root")
        .to_path_buf()
}

/// Run an installer binary with a controlled environment.
fn run(exe: &str, args: &[&str], empty_path: bool) -> Output {
    let mut cmd = Command::new(exe);
    cmd.args(args)
        .env("CUMULUS_DOTFILES_DIR", repo_root())
        .env("HOME", std::env::temp_dir());
    if empty_path {
        // No package managers / tools resolvable — forces the manual-install
        // fallback branch deterministically.
        cmd.env("PATH", "");
    }
    cmd.output().expect("spawn installer")
}

const FONTS: &str = env!("CARGO_BIN_EXE_cumulus-install-fonts");
const APPS: &str = env!("CARGO_BIN_EXE_cumulus-install-apps");
const DEVOPS: &str = env!("CARGO_BIN_EXE_cumulus-install-devops");
const NVIM_DEPS: &str = env!("CARGO_BIN_EXE_cumulus-install-nvim-deps");
const SDKMAN: &str = env!("CARGO_BIN_EXE_cumulus-install-sdkman");

#[test]
fn help_exits_zero_and_omits_shebang() {
    for exe in [FONTS, APPS, DEVOPS, NVIM_DEPS, SDKMAN] {
        let out = run(exe, &["--help"], false);
        assert!(out.status.success(), "help should exit 0 for {exe}");
        let text = String::from_utf8_lossy(&out.stdout);
        assert!(
            !text.contains("#!/usr/bin/env"),
            "help must not leak the shebang for {exe}"
        );
        assert!(text.contains("Usage:"), "help should show usage for {exe}");
    }
}

#[test]
fn unknown_option_fails_with_message() {
    let out = run(FONTS, &["--bogus"], false);
    assert!(!out.status.success());
    assert_eq!(out.status.code(), Some(1));
    let err = String::from_utf8_lossy(&out.stderr);
    assert!(err.contains("Unknown option: --bogus"), "stderr was: {err}");
}

#[test]
fn dry_run_never_executes_and_announces_itself() {
    // With PATH cleared, nothing is "already installed", so dry-run must emit
    // `+ ` command previews and the "DRY RUN" banner, and still exit 0.
    let out = run(FONTS, &["--dry-run"], true);
    assert!(out.status.success(), "dry-run should exit 0: {out:?}");
    let text = String::from_utf8_lossy(&out.stdout);
    assert!(text.contains("DRY RUN"), "missing banner: {text}");
    assert!(text.contains("+ "), "missing command preview: {text}");
}

#[test]
fn nvim_deps_no_package_manager_exits_one() {
    // apt/pacman unresolvable -> the manual-install fallback + exit 1.
    let out = run(NVIM_DEPS, &[], true);
    assert!(!out.status.success());
    assert_eq!(out.status.code(), Some(1));
    let text = String::from_utf8_lossy(&out.stdout);
    assert!(
        text.contains("No supported package manager found"),
        "stdout was: {text}"
    );
}

#[test]
fn nvim_deps_dry_run_previews_neovim_download() {
    let out = run(NVIM_DEPS, &["--dry-run"], false);
    assert!(out.status.success(), "{out:?}");
    let text = String::from_utf8_lossy(&out.stdout);
    assert!(text.contains("DRY RUN"), "missing banner: {text}");
    assert!(
        text.contains("nvim-linux-x86_64.tar.gz"),
        "should preview the neovim tarball download: {text}"
    );
}
