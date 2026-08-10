//! Snapshot/restore/update maintenance commands. Ports `backup.sh`,
//! `restore.sh`, and `update.sh`.

use crate::context::Context;
use crate::error::{Error, Result};
use std::io::Write;
use std::path::Path;
use std::process::Command;

/// The managed targets, kept in sync with install.sh's LINKS map.
const TARGETS: [&str; 6] = [
    ".zshrc",
    ".config/cumulus/zsh_config",
    ".config/sway",
    ".config/wofi",
    ".config/waybar",
    ".config/kitty",
];

fn log(tag: &str, msg: &str) {
    println!("\x1b[1;34m[{tag}]\x1b[0m {msg}");
}

/// `date +<fmt>` for parity with the shell timestamps.
fn date(fmt: &str) -> String {
    Command::new("date")
        .arg(fmt)
        .output()
        .ok()
        .filter(|o| o.status.success())
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_default()
}

/// Directory entry names sorted by mtime, newest first (mirrors `ls -1t`).
fn entries_by_mtime(dir: &Path) -> Vec<String> {
    let mut items: Vec<(std::time::SystemTime, String)> = match std::fs::read_dir(dir) {
        Ok(rd) => rd
            .flatten()
            .map(|e| {
                let name = e.file_name().to_string_lossy().into_owned();
                let mtime = e
                    .metadata()
                    .and_then(|m| m.modified())
                    .unwrap_or(std::time::UNIX_EPOCH);
                (mtime, name)
            })
            .collect(),
        Err(_) => return Vec::new(),
    };
    // Newest first; ties broken by name descending to stay deterministic.
    items.sort_by(|a, b| b.0.cmp(&a.0).then_with(|| b.1.cmp(&a.1)));
    items.into_iter().map(|(_, n)| n).collect()
}

// ---------------------------------------------------------------------------
// backup
// ---------------------------------------------------------------------------

/// `cumulus-backup [--list]`.
pub fn run_backup(ctx: &Context, args: &[String]) -> Result<()> {
    let backups_dir = ctx.home.join("cumulus-backups");

    if args.first().map(String::as_str) == Some("--list") {
        log(
            "backup",
            &format!("Existing snapshots in {}:", backups_dir.display()),
        );
        if !backups_dir.is_dir() {
            println!("(none yet)");
        } else {
            for name in entries_by_mtime(&backups_dir) {
                println!("{name}");
            }
        }
        return Ok(());
    }

    std::fs::create_dir_all(&backups_dir)?;
    let stamp = date("+%Y%m%d_%H%M%S");
    let archive = backups_dir.join(format!("{stamp}.tar.gz"));

    let existing: Vec<&str> = TARGETS
        .iter()
        .copied()
        .filter(|t| ctx.home.join(t).exists())
        .collect();

    if existing.is_empty() {
        log(
            "backup",
            "Nothing to back up — no managed targets found under $HOME.",
        );
        return Ok(());
    }

    log("backup", &format!("Archiving: {}", existing.join(" ")));
    let mut cmd = Command::new("tar");
    cmd.arg("-czhf").arg(&archive).arg("-C").arg(&ctx.home);
    for t in &existing {
        cmd.arg(t);
    }
    let status = cmd.status()?;
    if !status.success() {
        return Err(Error::with_code("tar failed", 1));
    }
    log("backup", &format!("Saved: {}", archive.display()));
    Ok(())
}

// ---------------------------------------------------------------------------
// restore
// ---------------------------------------------------------------------------

/// `cumulus-restore [<timestamp>.tar.gz]`.
pub fn run_restore(ctx: &Context, args: &[String]) -> Result<()> {
    let backups_dir = ctx.home.join("cumulus-backups");
    let pre_restore_dir = ctx
        .home
        .join(".cumulus_backup")
        .join(format!("pre-restore_{}", date("+%Y%m%d_%H%M%S")));

    let mut archive_name = args.first().cloned().unwrap_or_default();
    if archive_name.is_empty() {
        archive_name = entries_by_mtime(&backups_dir)
            .into_iter()
            .next()
            .unwrap_or_default();
        if archive_name.is_empty() {
            log(
                "restore",
                &format!(
                    "No snapshots found in {}. Run backup.sh first.",
                    backups_dir.display()
                ),
            );
            return Err(Error::with_code("", 1));
        }
        log(
            "restore",
            &format!("No snapshot specified, using most recent: {archive_name}"),
        );
    }

    let archive = backups_dir.join(&archive_name);
    if !archive.is_file() {
        log(
            "restore",
            &format!("Snapshot not found: {}", archive.display()),
        );
        return Err(Error::with_code("", 1));
    }

    print!(
        "Restore {} over your current $HOME config? Existing files will be moved to {} first. [y/N] ",
        archive.display(),
        pre_restore_dir.display()
    );
    std::io::stdout().flush().ok();
    let mut reply = String::new();
    std::io::stdin().read_line(&mut reply).ok();
    let reply = reply.trim_start();
    if !reply.starts_with('y') && !reply.starts_with('Y') {
        log("restore", "Aborted.");
        return Ok(());
    }

    std::fs::create_dir_all(&pre_restore_dir)?;
    log(
        "restore",
        &format!(
            "Snapshotting current state to {} before overwriting...",
            pre_restore_dir.display()
        ),
    );
    for entry in archive_top_entries(&archive) {
        let live = ctx.home.join(&entry);
        if live.exists() {
            let dest = pre_restore_dir.join(&entry);
            if let Some(parent) = dest.parent() {
                let _ = std::fs::create_dir_all(parent);
            }
            // cp -a preserves symlinks/attrs; best-effort like the shell.
            let _ = Command::new("cp").arg("-a").arg(&live).arg(&dest).status();
        }
    }

    log(
        "restore",
        &format!("Extracting {} into $HOME...", archive.display()),
    );
    let status = Command::new("tar")
        .arg("-xzf")
        .arg(&archive)
        .arg("-C")
        .arg(&ctx.home)
        .status()?;
    if !status.success() {
        return Err(Error::with_code("tar extraction failed", 1));
    }

    log(
        "restore",
        &format!(
            "Done. Previous state saved at: {}",
            pre_restore_dir.display()
        ),
    );
    log(
        "restore",
        "Reload sway with: swaymsg reload   (or Mod+Shift+C)",
    );
    Ok(())
}

/// The unique first-two-path-components of a tarball's members (mirrors
/// `tar -tzf | sed 's:/$::' | awk -F/ '{print $1"/"$2}' | sort -u`).
fn archive_top_entries(archive: &Path) -> Vec<String> {
    let out = Command::new("tar").arg("-tzf").arg(archive).output();
    let Ok(out) = out else {
        return Vec::new();
    };
    if !out.status.success() {
        return Vec::new();
    }
    let mut set: Vec<String> = Vec::new();
    for line in String::from_utf8_lossy(&out.stdout).lines() {
        let trimmed = line.trim_end_matches('/');
        let parts: Vec<&str> = trimmed.split('/').collect();
        let key = match parts.as_slice() {
            [a] => a.to_string(),
            [a, b, ..] => format!("{a}/{b}"),
            _ => continue,
        };
        if !set.contains(&key) {
            set.push(key);
        }
    }
    set.sort();
    set
}

// ---------------------------------------------------------------------------
// update
// ---------------------------------------------------------------------------

/// `cumulus-update [install.sh args...]`.
pub fn run_update(ctx: &Context, args: &[String]) -> Result<()> {
    let dir = &ctx.dotfiles_dir;

    let porcelain = Command::new("git")
        .arg("-C")
        .arg(dir)
        .args(["status", "--porcelain"])
        .output()?;
    if !String::from_utf8_lossy(&porcelain.stdout).trim().is_empty() {
        log(
            "update",
            &format!("You have local uncommitted changes in {}:", dir.display()),
        );
        let _ = Command::new("git")
            .arg("-C")
            .arg(dir)
            .args(["status", "--short"])
            .status();
        log(
            "update",
            "Commit or stash them before updating, to avoid losing work.",
        );
        return Err(Error::with_code("", 1));
    }

    log("update", "Pulling latest changes...");
    let status = Command::new("git")
        .arg("-C")
        .arg(dir)
        .args(["pull", "--ff-only"])
        .status()?;
    if !status.success() {
        return Err(Error::with_code("git pull failed", 1));
    }

    log(
        "update",
        &format!("Re-running cumulus install {}", args.join(" ")),
    );
    crate::install::deploy::run(ctx, args)?;

    log("update", "Update complete.");
    Ok(())
}
