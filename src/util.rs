//! Filesystem and process helpers shared by all subcommands.

use crate::error::{Error, Result};
use std::fs;
use std::io::Write;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};

/// Print a magenta `[tag]` log line to stdout (mirrors the shell `log` helper).
pub fn log(tag: &str, msg: &str) {
    println!("\x1b[1;35m[{tag}]\x1b[0m {msg}");
}

/// Print a bold-red warning to stderr.
pub fn warn(tag: &str, msg: &str) {
    eprintln!("\x1b[1;33m[{tag}] warning:\x1b[0m {msg}");
}

/// Whether `path` is a symlink (without following it).
pub fn is_symlink(path: &Path) -> bool {
    fs::symlink_metadata(path)
        .map(|m| m.file_type().is_symlink())
        .unwrap_or(false)
}

/// Whether `path` is an executable regular file.
pub fn is_executable(path: &Path) -> bool {
    fs::metadata(path)
        .map(|m| m.is_file() && m.permissions().mode() & 0o111 != 0)
        .unwrap_or(false)
}

fn rand_suffix() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0);
    format!("{:x}{:x}", std::process::id(), nanos)
}

/// Create a fresh, empty temporary file inside `dir`.
pub fn mktemp(dir: &Path, prefix: &str) -> Result<PathBuf> {
    for _ in 0..16 {
        let path = dir.join(format!("{prefix}{}", rand_suffix()));
        match fs::OpenOptions::new()
            .write(true)
            .create_new(true)
            .open(&path)
        {
            Ok(mut f) => {
                f.write_all(b"")?;
                return Ok(path);
            }
            Err(e) if e.kind() == std::io::ErrorKind::AlreadyExists => continue,
            Err(e) => return Err(e.into()),
        }
    }
    Err(Error::new("could not create temporary file"))
}

/// Create a fresh temporary directory inside `dir`.
pub fn mktemp_dir(dir: &Path, prefix: &str) -> Result<PathBuf> {
    for _ in 0..16 {
        let path = dir.join(format!("{prefix}{}", rand_suffix()));
        match fs::create_dir(&path) {
            Ok(()) => return Ok(path),
            Err(e) if e.kind() == std::io::ErrorKind::AlreadyExists => continue,
            Err(e) => return Err(e.into()),
        }
    }
    Err(Error::new("could not create temporary directory"))
}

/// Atomically write `contents` to `path` via a sibling temp file + rename,
/// applying `mode` to the final file. Rejects values containing newlines only
/// when `reject_newlines` is set (used for the theme state file).
pub fn write_atomic(path: &Path, contents: &str, mode: u32) -> Result<()> {
    let dir = path
        .parent()
        .ok_or_else(|| Error::new("cannot write to a path without a parent directory"))?;
    fs::create_dir_all(dir)?;
    let tmp = mktemp(dir, ".tmp.")?;
    fs::write(&tmp, contents)?;
    fs::set_permissions(&tmp, fs::Permissions::from_mode(mode))?;
    if let Err(e) = fs::rename(&tmp, path) {
        let _ = fs::remove_file(&tmp);
        return Err(e.into());
    }
    Ok(())
}

/// Absolute path with the parent directory canonicalized (mirrors
/// `cd "$(dirname)" && pwd`) without resolving the leaf component.
pub fn absolutize(path: &Path) -> PathBuf {
    let parent = path.parent().filter(|p| !p.as_os_str().is_empty());
    let file = path.file_name();
    match (parent, file) {
        (Some(parent), Some(file)) => {
            let parent_abs = if parent.is_absolute() {
                parent.to_path_buf()
            } else {
                std::env::current_dir().unwrap_or_default().join(parent)
            };
            let parent_canon = fs::canonicalize(&parent_abs).unwrap_or(parent_abs);
            parent_canon.join(file)
        }
        _ => path.to_path_buf(),
    }
}

/// Basename of a string path, falling back to the whole string.
pub fn basename(path: &str) -> String {
    Path::new(path)
        .file_name()
        .and_then(|s| s.to_str())
        .unwrap_or(path)
        .to_string()
}

/// Whether `name` resolves to an executable on `PATH` (mirrors
/// `command -v <name>`).
pub fn command_exists(name: &str) -> bool {
    if name.contains('/') {
        return is_executable(Path::new(name));
    }
    let Some(path) = std::env::var_os("PATH") else {
        return false;
    };
    std::env::split_paths(&path).any(|dir| is_executable(&dir.join(name)))
}

/// The login name of the current user (mirrors `id -un`).
pub fn current_username() -> Option<String> {
    let out = std::process::Command::new("id").arg("-un").output().ok()?;
    if !out.status.success() {
        return None;
    }
    let name = String::from_utf8_lossy(&out.stdout).trim().to_string();
    (!name.is_empty()).then_some(name)
}

/// The owning username of `path` via `stat -c '%U'` (mirrors the shell check).
pub fn path_owner(path: &Path) -> Option<String> {
    let out = std::process::Command::new("stat")
        .args(["-c", "%U"])
        .arg(path)
        .output()
        .ok()?;
    if !out.status.success() {
        return None;
    }
    let name = String::from_utf8_lossy(&out.stdout).trim().to_string();
    (!name.is_empty()).then_some(name)
}

/// Whether `path` is a Unix socket.
pub fn is_socket(path: &Path) -> bool {
    use std::os::unix::fs::FileTypeExt;
    fs::symlink_metadata(path)
        .map(|m| m.file_type().is_socket())
        .unwrap_or(false)
}
