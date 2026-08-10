//! Integration tests for the `theme` command of the cumulus binary suite.
//!
//! These mirror the behavioural contracts of the original Bash test suite
//! (`tests/palettes.sh`, `tests/theme-rendering.sh`, `tests/state-safety.sh`)
//! and prove parity of the Rust port. Each test runs the compiled
//! `cumulus-theme` binary against an isolated copy of the repository.

use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Output};

fn repo_root() -> PathBuf {
    // <repo>/rust/cumulus-dotfiles -> <repo>
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(2)
        .expect("repo root")
        .to_path_buf()
}

fn bin() -> PathBuf {
    PathBuf::from(env!("CARGO_BIN_EXE_cumulus-theme"))
}

struct Sandbox {
    dir: PathBuf,
    repo: PathBuf,
    home: PathBuf,
}

impl Sandbox {
    fn new() -> Sandbox {
        let dir =
            std::env::temp_dir().join(format!("cumulus-test-{}-{}", std::process::id(), uniq()));
        let repo = dir.join("repo");
        let home = dir.join("home");
        fs::create_dir_all(&home).unwrap();
        copy_dir(&repo_root(), &repo);
        Sandbox { dir, repo, home }
    }

    fn run(&self, args: &[&str]) -> Output {
        Command::new(bin())
            .args(args)
            .env("HOME", &self.home)
            .env("CUMULUS_DOTFILES_DIR", &self.repo)
            .env("CUMULUS_SKIP_RELOAD", "1")
            .env("CUMULUS_SKIP_SYSTEMD", "1")
            .output()
            .expect("run binary")
    }

    fn state(&self) -> String {
        fs::read_to_string(self.home.join(".config/cumulus/theme/state")).unwrap_or_default()
    }
    fn read(&self, rel: &str) -> String {
        fs::read_to_string(self.repo.join(rel)).unwrap_or_default()
    }
}

impl Drop for Sandbox {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.dir);
    }
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
            if let Ok(meta) = fs::metadata(&from) {
                let _ = fs::set_permissions(&to, meta.permissions());
            }
        }
    }
}

fn stdout(o: &Output) -> String {
    String::from_utf8_lossy(&o.stdout).into_owned()
}
fn combined(o: &Output) -> String {
    format!(
        "{}{}",
        String::from_utf8_lossy(&o.stdout),
        String::from_utf8_lossy(&o.stderr)
    )
}

const FLAVORS: [&str; 4] = ["aws", "azure", "gcp", "oci"];

#[test]
fn list_registers_every_flavor() {
    let sb = Sandbox::new();
    let out = sb.run(&["list"]);
    assert!(out.status.success());
    let text = stdout(&out);
    for f in FLAVORS {
        let count = text
            .lines()
            .filter(|l| l.starts_with(&format!("  {f} ")))
            .count();
        assert_eq!(count, 1, "expected one registry entry for {f}\n{text}");
    }
}

#[test]
fn incomplete_palette_is_rejected() {
    let sb = Sandbox::new();
    let palette = sb.repo.join("themes/palettes/aws.conf");
    let stripped: String = fs::read_to_string(&palette)
        .unwrap()
        .lines()
        .filter(|l| !l.starts_with("BLUE="))
        .collect::<Vec<_>>()
        .join("\n");
    fs::write(&palette, stripped).unwrap();
    let out = sb.run(&["set", "aws", "--flat"]);
    assert!(!out.status.success());
    assert!(
        combined(&out).contains("missing required variable: BLUE"),
        "{}",
        combined(&out)
    );
}

#[test]
fn flat_mode_renders_all_configs() {
    for flavor in FLAVORS {
        let sb = Sandbox::new();
        assert!(sb.run(&["set", flavor, "--flat"]).status.success());
        let base = sb
            .read(&format!("themes/palettes/{flavor}.conf"))
            .lines()
            .find_map(|l| {
                l.strip_prefix("BASE=")
                    .map(|v| v.trim_matches('"').to_string())
            })
            .unwrap();


        let waybar = sb.read("config/waybar/style.css");
        assert!(waybar.contains("window#waybar {"));
        assert!(waybar.contains(&format!("background-color: {base};")));
        for ph in [
            "@@BASE@@",
            "@@TEXT@@",
            "@@SUBTEXT0@@",
            "@@SURFACE0@@",
            "@@BLUE@@",
            "@@RED@@",
            "@@YELLOW@@",
        ] {
            assert!(
                !waybar.contains(ph),
                "unresolved {ph} in waybar css for {flavor}"
            );
        }
        let wofi = sb.read("config/wofi/style.css");
        for ph in ["@@BASE@@", "@@TEXT@@", "@@SURFACE0@@", "@@BLUE@@"] {
            assert!(
                !wofi.contains(ph),
                "unresolved {ph} in wofi css for {flavor}"
            );
        }
        let sway = sb.read("config/sway/colors.conf");
        assert!(sway.contains(&format!(
            "exec_always pkill -x swaybg; swaybg -c \"{base}\""
        )));
    }
}

#[test]
fn rendering_is_idempotent() {
    let sb = Sandbox::new();
    assert!(sb.run(&["set", "oci", "--flat"]).status.success());
    let first_sway = sb.read("config/sway/colors.conf");
    let first_waybar = sb.read("config/waybar/style.css");
    assert!(sb.run(&["set", "oci", "--flat"]).status.success());
    assert_eq!(first_sway, sb.read("config/sway/colors.conf"));
    assert_eq!(first_waybar, sb.read("config/waybar/style.css"));
}

#[test]
fn broken_template_aborts_without_partial_write() {
    let sb = Sandbox::new();
    assert!(sb.run(&["set", "aws", "--flat"]).status.success());
    let before = sb.read("config/waybar/style.css");
    let tmpl = sb.repo.join("config/waybar/style.css.tmpl");
    let content = fs::read_to_string(&tmpl)
        .unwrap()
        .replace("@@BASE@@", "REMOVED");
    fs::write(&tmpl, content).unwrap();
    let out = sb.run(&["set", "gcp", "--flat"]);
    assert!(!out.status.success());
    assert!(combined(&out).contains("missing placeholder @@BASE@@"));
    assert_eq!(
        before,
        sb.read("config/waybar/style.css"),
        "partial write occurred"
    );
}

#[test]
fn wallpaper_state_is_complete_and_verbatim() {
    let sb = Sandbox::new();
    let wallpaper = sb.dir.join("wall paper & image.png");
    fs::write(&wallpaper, "wallpaper").unwrap();
    let wp = wallpaper.to_string_lossy().into_owned();
    assert!(sb.run(&["set", "aws", "--wallpaper", &wp]).status.success());
    assert!(sb.run(&["apply"]).status.success());
    let state = sb.state();
    for key in [
        "FLAVOR",
        "MODE",
        "WALLPAPER",
        "WALLPAPER_SOURCE",
        "INTERVAL",
        "NVIM_COLORSCHEME",
    ] {
        assert!(
            state.lines().any(|l| l.starts_with(&format!("{key}="))),
            "missing {key}\n{state}"
        );
    }
    assert!(
        state.lines().any(|l| l == format!("WALLPAPER={wp}")),
        "not verbatim\n{state}"
    );
}

#[test]
fn wallpaper_path_is_never_shell_evaluated() {
    let sb = Sandbox::new();
    let marker = sb.dir.join("generated-command-ran");
    let dangerous = sb.dir.join("$(touch generated-command-ran);'wallpaper.png");
    fs::write(&dangerous, "wallpaper").unwrap();
    let _ = sb.run(&["set", "aws", "--wallpaper", &dangerous.to_string_lossy()]);
    assert!(!marker.exists(), "wallpaper path was shell-evaluated");
}

#[test]
fn state_values_are_never_shell_evaluated_on_apply() {
    let sb = Sandbox::new();
    let marker = sb.dir.join("state-command-ran");
    let theme_dir = sb.home.join(".config/cumulus/theme");
    fs::create_dir_all(&theme_dir).unwrap();
    fs::write(
        theme_dir.join("state"),
        format!("FLAVOR=aws\nMODE=flat\nWALLPAPER=$(touch {})\nWALLPAPER_SOURCE=flat\nINTERVAL=30m\nNVIM_COLORSCHEME=aws-theme\n", marker.display()),
    )
    .unwrap();
    assert!(sb.run(&["apply"]).status.success());
    assert!(!marker.exists(), "state value was shell-evaluated");
}

#[test]
fn legacy_state_is_migrated() {
    let sb = Sandbox::new();
    let theme_dir = sb.home.join(".config/cumulus/theme");
    fs::create_dir_all(&theme_dir).unwrap();
    let svg = sb.repo.join("themes/wallpapers/aws.svg");
    fs::write(
        theme_dir.join("state"),
        format!(
            "FLAVOR=aws\nMODE=wallpaper\nWALLPAPER={}\nINTERVAL=30m\n",
            svg.display()
        ),
    )
    .unwrap();
    assert!(sb.run(&["apply"]).status.success());
    let state = sb.state();
    assert!(state.contains("WALLPAPER_SOURCE=theme-default"), "{state}");
    assert!(state.contains("NVIM_COLORSCHEME=aws-theme"), "{state}");
}

#[test]
fn invalid_saved_source_is_rejected() {
    let sb = Sandbox::new();
    let theme_dir = sb.home.join(".config/cumulus/theme");
    fs::create_dir_all(&theme_dir).unwrap();
    let svg = sb.repo.join("themes/wallpapers/aws.svg");
    fs::write(
        theme_dir.join("state"),
        format!("FLAVOR=aws\nMODE=wallpaper\nWALLPAPER={}\nWALLPAPER_SOURCE=invalid\nINTERVAL=30m\nNVIM_COLORSCHEME=aws-theme\n", svg.display()),
    )
    .unwrap();
    assert!(
        !sb.run(&["apply"]).status.success(),
        "invalid source accepted"
    );
}

#[test]
fn invalid_saved_mode_falls_back_to_flat() {
    let sb = Sandbox::new();
    let theme_dir = sb.home.join(".config/cumulus/theme");
    fs::create_dir_all(&theme_dir).unwrap();
    fs::write(
        theme_dir.join("state"),
        "FLAVOR=aws\nMODE=invalid\nWALLPAPER=/missing.png\nWALLPAPER_SOURCE=invalid\nINTERVAL=30m\n",
    )
    .unwrap();
    assert!(sb.run(&["apply"]).status.success());
    assert!(sb.state().contains("MODE=flat"));
}

#[test]
fn rotate_then_next_cycles_flavor_wallpapers() {
    let sb = Sandbox::new();
    assert!(sb.run(&["set", "oci", "--rotate"]).status.success());
    let first = wallpaper_of(&sb.state());
    assert!(sb.run(&["next"]).status.success());
    let second = wallpaper_of(&sb.state());
    assert_ne!(first, second, "next did not advance");
    assert!(second.contains("oci"), "left oci pool: {second}");
}

fn wallpaper_of(state: &str) -> String {
    state
        .lines()
        .find_map(|l| l.strip_prefix("WALLPAPER="))
        .unwrap_or("")
        .to_string()
}

#[test]
fn unknown_flavor_is_rejected() {
    let sb = Sandbox::new();
    let out = sb.run(&["set", "nope", "--flat"]);
    assert!(!out.status.success());
    assert!(combined(&out).contains("unknown flavor 'nope'"));
}

#[test]
fn help_exits_zero() {
    let sb = Sandbox::new();
    let out = sb.run(&["--help"]);
    assert!(out.status.success());
    assert!(stdout(&out).contains("cumulus-theme"));
}

#[test]
fn current_reports_no_state_initially() {
    let sb = Sandbox::new();
    let out = sb.run(&["current"]);
    assert!(out.status.success());
    assert!(stdout(&out).contains("No theme set yet"));
}

#[test]
fn umbrella_binary_dispatches_theme() {
    // `cumulus theme list` should work identically to `cumulus-theme list`.
    let sb = Sandbox::new();
    let umbrella = PathBuf::from(env!("CARGO_BIN_EXE_cumulus"));
    let out = Command::new(umbrella)
        .args(["theme", "list"])
        .env("HOME", &sb.home)
        .env("CUMULUS_DOTFILES_DIR", &sb.repo)
        .output()
        .unwrap();
    assert!(out.status.success());
    assert!(stdout(&out).contains("Flavors:"));
}
