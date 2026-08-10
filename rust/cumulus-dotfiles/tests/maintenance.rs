//! Integration tests for backup / restore / update.

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

struct Home {
    dir: PathBuf,
}

impl Home {
    fn new() -> Home {
        let dir =
            std::env::temp_dir().join(format!("cumulus-maint-{}-{}", std::process::id(), uniq()));
        fs::create_dir_all(&dir).unwrap();
        Home { dir }
    }

    fn write(&self, rel: &str, body: &str) {
        let p = self.dir.join(rel);
        fs::create_dir_all(p.parent().unwrap()).unwrap();
        fs::write(p, body).unwrap();
    }

    fn run(&self, exe: &str, args: &[&str], stdin: Option<&str>) -> Output {
        use std::io::Write;
        use std::process::Stdio;
        let mut child = Command::new(exe)
            .args(args)
            .env("HOME", &self.dir)
            .env("CUMULUS_DOTFILES_DIR", repo_root())
            .stdin(if stdin.is_some() {
                Stdio::piped()
            } else {
                Stdio::null()
            })
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .expect("spawn");
        if let Some(s) = stdin {
            child.stdin.take().unwrap().write_all(s.as_bytes()).unwrap();
        }
        child.wait_with_output().expect("wait")
    }
}

impl Drop for Home {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.dir);
    }
}

const BACKUP: &str = env!("CARGO_BIN_EXE_cumulus-backup");
const RESTORE: &str = env!("CARGO_BIN_EXE_cumulus-restore");

#[test]
fn backup_with_no_targets_is_a_noop() {
    let home = Home::new();
    let out = home.run(BACKUP, &[], None);
    assert!(out.status.success());
    assert!(String::from_utf8_lossy(&out.stdout).contains("Nothing to back up"));
    assert!(
        !home.dir.join("cumulus-backups").exists() || {
            // The dir may be created but must contain no archives.
            fs::read_dir(home.dir.join("cumulus-backups"))
                .map(|d| d.count() == 0)
                .unwrap_or(true)
        }
    );
}

#[test]
fn backup_then_list_shows_the_snapshot() {
    let home = Home::new();
    home.write(".zshrc", "hello\n");
    let out = home.run(BACKUP, &[], None);
    assert!(out.status.success(), "{:?}", out);
    assert!(String::from_utf8_lossy(&out.stdout).contains("Saved:"));

    let list = home.run(BACKUP, &["--list"], None);
    let stdout = String::from_utf8_lossy(&list.stdout);
    assert!(stdout.contains(".tar.gz"), "list was: {stdout}");
}

#[test]
fn list_without_backups_says_none_yet() {
    let home = Home::new();
    let out = home.run(BACKUP, &["--list"], None);
    assert!(String::from_utf8_lossy(&out.stdout).contains("(none yet)"));
}

#[test]
fn restore_without_snapshots_fails() {
    let home = Home::new();
    let out = home.run(RESTORE, &[], None);
    assert_eq!(out.status.code(), Some(1));
    assert!(String::from_utf8_lossy(&out.stdout).contains("No snapshots found"));
}

#[test]
fn restore_roundtrip_recovers_original_and_snapshots_current() {
    let home = Home::new();
    home.write(".config/sway/config", "original\n");
    home.write(".zshrc", "z\n");
    assert!(home.run(BACKUP, &[], None).status.success());

    // Mutate, then abort a restore -> mutation preserved.
    home.write(".config/sway/config", "changed\n");
    let abort = home.run(RESTORE, &[], Some("n\n"));
    assert!(abort.status.success());
    assert_eq!(
        fs::read_to_string(home.dir.join(".config/sway/config")).unwrap(),
        "changed\n"
    );

    // Confirm a restore -> original recovered, pre-restore snapshot exists.
    let yes = home.run(RESTORE, &[], Some("y\n"));
    assert!(yes.status.success(), "{:?}", yes);
    assert_eq!(
        fs::read_to_string(home.dir.join(".config/sway/config")).unwrap(),
        "original\n"
    );
    assert!(home.dir.join(".cumulus_backup").is_dir());
}
