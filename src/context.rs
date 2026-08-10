//! Runtime context: the dotfiles checkout, HOME, and derived paths.

use crate::error::{Error, Result};
use std::env;
use std::fs;
use std::path::PathBuf;

/// Resolved paths shared by every subcommand.
pub struct Context {
    /// Root of the cumulus.dotfiles checkout (the source of truth).
    pub dotfiles_dir: PathBuf,
    /// The user's home directory.
    pub home: PathBuf,
}

impl Context {
    /// Discover the context from the environment: HOME plus the dotfiles
    /// checkout (`CUMULUS_DOTFILES_DIR`, else derived from the executable).
    pub fn discover() -> Result<Context> {
        let home = env::var_os("HOME")
            .map(PathBuf::from)
            .ok_or_else(|| Error::new("HOME is not set"))?;
        let dotfiles_dir = locate_dotfiles_dir()?;
        Ok(Context { dotfiles_dir, home })
    }

    pub fn palettes_dir(&self) -> PathBuf {
        self.dotfiles_dir.join("themes/palettes")
    }
    pub fn wallpapers_dir(&self) -> PathBuf {
        self.dotfiles_dir.join("themes/wallpapers")
    }
    pub fn config_src(&self, rel: &str) -> PathBuf {
        self.dotfiles_dir.join("config").join(rel)
    }
    pub fn state_dir(&self) -> PathBuf {
        self.home.join(".config/cumulus/theme")
    }
    pub fn state_file(&self) -> PathBuf {
        self.state_dir().join("state")
    }
    pub fn systemd_user_dir(&self) -> PathBuf {
        self.home.join(".config/systemd/user")
    }
}

/// Find the repo root. Priority:
/// 1. `CUMULUS_DOTFILES_DIR` env var
/// 2. Current working directory
/// 3. `$HOME/cumulus.dotfiles` or `$HOME/.cumulus.dotfiles`
/// 4. Ancestors of executable
fn locate_dotfiles_dir() -> Result<PathBuf> {
    if let Some(dir) = env::var_os("CUMULUS_DOTFILES_DIR") {
        let p = PathBuf::from(dir);
        if p.join("themes/palettes").is_dir() {
            return Ok(p);
        }
        return Err(Error::new(
            "CUMULUS_DOTFILES_DIR does not point at a cumulus.dotfiles checkout",
        ));
    }

    if let Ok(cwd) = env::current_dir() {
        if cwd.join("themes/palettes").is_dir() {
            return Ok(cwd);
        }
    }

    if let Some(home) = env::var_os("HOME").map(PathBuf::from) {
        let candidate1 = home.join("cumulus.dotfiles");
        if candidate1.join("themes/palettes").is_dir() {
            return Ok(candidate1);
        }
        let candidate2 = home.join(".cumulus.dotfiles");
        if candidate2.join("themes/palettes").is_dir() {
            return Ok(candidate2);
        }
    }

    let exe =
        env::current_exe().map_err(|_| Error::new("cannot resolve current executable path"))?;
    let exe = fs::canonicalize(&exe).unwrap_or(exe);
    for ancestor in exe.ancestors() {
        if ancestor.join("themes/palettes").is_dir() {
            return Ok(ancestor.to_path_buf());
        }
    }
    Err(Error::new(
        "could not locate the cumulus.dotfiles checkout (set CUMULUS_DOTFILES_DIR)",
    ))
}
