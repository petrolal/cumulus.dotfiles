//! The persisted theme state file (`~/.config/cumulus/theme/state`).

use crate::bail;
use crate::context::Context;
use crate::error::Result;
use crate::util;
use std::fs;

/// The six data-only fields persisted between runs.
#[derive(Default, Clone)]
pub struct State {
    pub flavor: String,
    pub mode: String,
    pub wallpaper: String,
    pub wallpaper_source: String,
    pub interval: String,
    pub nvim_colorscheme: String,
}

impl State {
    /// Load state, tolerating a missing file (all fields default to empty).
    pub fn load(ctx: &Context) -> State {
        let mut s = State::default();
        let content = fs::read_to_string(ctx.state_file()).unwrap_or_default();
        for line in content.lines() {
            if let Some((key, value)) = line.split_once('=') {
                match key {
                    "FLAVOR" => s.flavor = value.to_string(),
                    "MODE" => s.mode = value.to_string(),
                    "WALLPAPER" => s.wallpaper = value.to_string(),
                    "WALLPAPER_SOURCE" => s.wallpaper_source = value.to_string(),
                    "INTERVAL" => s.interval = value.to_string(),
                    "NVIM_COLORSCHEME" => s.nvim_colorscheme = value.to_string(),
                    _ => {}
                }
            }
        }
        s
    }

    /// Persist state atomically (`0600`), rejecting embedded newlines.
    pub fn write(&self, ctx: &Context) -> Result<()> {
        for value in [
            &self.flavor,
            &self.mode,
            &self.wallpaper,
            &self.wallpaper_source,
            &self.interval,
            &self.nvim_colorscheme,
        ] {
            if value.contains('\n') || value.contains('\r') {
                bail!("theme state values cannot contain newlines");
            }
        }
        let body = format!(
            "FLAVOR={}\nMODE={}\nWALLPAPER={}\nWALLPAPER_SOURCE={}\nINTERVAL={}\nNVIM_COLORSCHEME={}\n",
            self.flavor,
            self.mode,
            self.wallpaper,
            self.wallpaper_source,
            self.interval,
            self.nvim_colorscheme
        );
        util::write_atomic(&ctx.state_file(), &body, 0o600)
    }
}
