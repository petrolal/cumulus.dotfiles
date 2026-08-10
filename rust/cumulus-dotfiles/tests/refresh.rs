//! Integration tests for the runtime-refresh / os-colorscheme / rgb-theme
//! adapter commands. These mirror `tests/runtime-refresh.sh` and prove the
//! best-effort, non-fatal contract of the ported adapters.

use std::fs;
use std::path::PathBuf;
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

struct Env {
    home: PathBuf,
}

impl Env {
    fn new() -> Env {
        let home =
            std::env::temp_dir().join(format!("cumulus-refresh-{}-{}", std::process::id(), uniq()));
        fs::create_dir_all(&home).unwrap();
        Env { home }
    }

    fn write_state(&self, body: &str) {
        let dir = self.home.join(".config/cumulus/theme");
        fs::create_dir_all(&dir).unwrap();
        fs::write(dir.join("state"), body).unwrap();
    }

    fn run(&self, exe: &str, args: &[&str]) -> Output {
        Command::new(exe)
            .args(args)
            .env("HOME", &self.home)
            .env("CUMULUS_DOTFILES_DIR", repo_root())
            .output()
            .expect("run binary")
    }
}

impl Drop for Env {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.home);
    }
}

#[test]
fn runtime_refresh_without_state_is_a_noop() {
    let env = Env::new();
    let out = env.run(env!("CARGO_BIN_EXE_cumulus-runtime-refresh"), &[]);
    assert!(out.status.success());
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(
        stdout.contains("No theme state; nothing to refresh."),
        "stdout was: {stdout}"
    );
}

#[test]
fn runtime_refresh_with_state_exits_zero_and_summarizes() {
    let env = Env::new();
    env.write_state("FLAVOR=aws\nMODE=flat\n");
    let out = env.run(env!("CARGO_BIN_EXE_cumulus-runtime-refresh"), &[]);
    // Best-effort: always exits 0 whether adapters are present or not.
    assert!(out.status.success());
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(stdout.contains("Refresh result:"), "stdout was: {stdout}");
}

#[test]
fn os_colorscheme_never_fails() {
    let env = Env::new();
    let out = env.run(env!("CARGO_BIN_EXE_cumulus-os-colorscheme"), &[]);
    // Unsupported desktops are reported as deferred, never fatal.
    assert!(out.status.success());
}

#[test]
fn rgb_theme_reports_status_via_exit_code() {
    let env = Env::new();
    let out = env.run(env!("CARGO_BIN_EXE_cumulus-rgb-theme"), &["aws"]);
    // No RGB controllers in CI -> exit 1, and no error text is printed.
    let code = out.status.code().unwrap_or(-1);
    assert!(code == 0 || code == 1, "unexpected exit code {code}");
    if code == 1 {
        assert!(
            out.stderr.is_empty() || String::from_utf8_lossy(&out.stderr).trim().is_empty(),
            "rgb-theme should exit silently on no-update"
        );
    }
}

#[test]
fn umbrella_dispatches_runtime_refresh() {
    let env = Env::new();
    let out = env.run(env!("CARGO_BIN_EXE_cumulus"), &["runtime-refresh"]);
    assert!(out.status.success());
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(stdout.contains("No theme state"), "stdout was: {stdout}");
}
