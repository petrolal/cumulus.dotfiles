//! Palette loading, parsing, and validation.

use crate::bail;
use crate::context::Context;
use crate::error::Result;
use std::collections::HashMap;
use std::fs;
use std::path::Path;

/// The 24 required `#rrggbb` colour variables every palette must define.
pub const COLOR_VARS: [&str; 24] = [
    "BASE",
    "MANTLE",
    "CRUST",
    "TEXT",
    "SUBTEXT1",
    "SUBTEXT0",
    "SURFACE0",
    "SURFACE1",
    "SURFACE2",
    "OVERLAY0",
    "BLUE",
    "LAVENDER",
    "SAPPHIRE",
    "SKY",
    "TEAL",
    "GREEN",
    "YELLOW",
    "PEACH",
    "MAROON",
    "RED",
    "MAUVE",
    "PINK",
    "FLAMINGO",
    "ROSEWATER",
];

/// A parsed palette file (`themes/palettes/<flavor>.sh`).
pub struct Palette {
    vars: HashMap<String, String>,
}

impl Palette {
    /// Look up a variable, returning `""` when absent.
    pub fn get(&self, key: &str) -> &str {
        self.vars.get(key).map(String::as_str).unwrap_or("")
    }

    /// The palette's Neovim colorscheme metadata value.
    pub fn nvim(&self) -> &str {
        self.get("NVIM_COLORSCHEME")
    }

    /// Load and parse the palette for `flavor` (no shell evaluation).
    pub fn load(ctx: &Context, flavor: &str) -> Palette {
        let path = ctx.palettes_dir().join(format!("{flavor}.sh"));
        Palette {
            vars: parse_file(&path),
        }
    }

    /// Validate the palette against the contract, with the same error messages
    /// as the original `validate_palette` shell function.
    pub fn validate(&self, flavor: &str) -> Result<()> {
        for var in ["THEME_NAME", "THEME_LABEL", "NVIM_COLORSCHEME"] {
            if self.get(var).is_empty() {
                bail!("palette '{flavor}' is missing metadata: {var}");
            }
        }
        if self.get("THEME_NAME") != flavor {
            bail!(
                "palette '{flavor}' has mismatched THEME_NAME: {}",
                self.get("THEME_NAME")
            );
        }
        if !is_nvim_colorscheme(self.nvim()) {
            bail!(
                "palette '{flavor}' has invalid NVIM_COLORSCHEME: {}",
                self.nvim()
            );
        }
        for var in COLOR_VARS {
            let value = self.get(var);
            if value.is_empty() {
                bail!("palette '{flavor}' is missing required variable: {var}");
            }
            if !is_hex_color(value) {
                bail!("palette '{flavor}' has invalid hex color for {var}: {value}");
            }
        }
        Ok(())
    }
}

/// Ensure the waybar/wofi templates exist and still contain their placeholders.
pub fn validate_templates(ctx: &Context) -> Result<()> {
    for template in [
        ctx.config_src("waybar/style.css.tmpl"),
        ctx.config_src("wofi/style.css.tmpl"),
    ] {
        let content = match fs::read_to_string(&template) {
            Ok(c) => c,
            Err(_) => bail!("missing theme template: {}", template.display()),
        };
        for placeholder in ["@@BASE@@", "@@TEXT@@", "@@SURFACE0@@", "@@BLUE@@"] {
            if !content.contains(placeholder) {
                bail!(
                    "theme template is missing placeholder {placeholder}: {}",
                    template.display()
                );
            }
        }
    }
    Ok(())
}

fn parse_file(path: &Path) -> HashMap<String, String> {
    let content = fs::read_to_string(path).unwrap_or_default();
    let mut map = HashMap::new();
    for line in content.lines() {
        let line = line.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        if let Some((key, value)) = line.split_once('=') {
            let key = key.trim();
            if key.is_empty() {
                continue;
            }
            let mut value = value.trim();
            if value.len() >= 2
                && ((value.starts_with('"') && value.ends_with('"'))
                    || (value.starts_with('\'') && value.ends_with('\'')))
            {
                value = &value[1..value.len() - 1];
            }
            map.insert(key.to_string(), value.to_string());
        }
    }
    map
}

/// `^#[[:xdigit:]]{6}$`
pub fn is_hex_color(v: &str) -> bool {
    let b = v.as_bytes();
    b.len() == 7 && b[0] == b'#' && b[1..].iter().all(|c| c.is_ascii_hexdigit())
}

/// `^[A-Za-z0-9_.-]+$`
pub fn is_nvim_colorscheme(v: &str) -> bool {
    !v.is_empty()
        && v.bytes()
            .all(|c| c.is_ascii_alphanumeric() || c == b'_' || c == b'.' || c == b'-')
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hex_validation() {
        assert!(is_hex_color("#16191D"));
        assert!(is_hex_color("#abcdef"));
        assert!(!is_hex_color("#abc"));
        assert!(!is_hex_color("16191D"));
        assert!(!is_hex_color("#16191Z"));
    }

    #[test]
    fn colorscheme_validation() {
        assert!(is_nvim_colorscheme("oci-theme"));
        assert!(is_nvim_colorscheme("aws_theme.v2"));
        assert!(!is_nvim_colorscheme(""));
        assert!(!is_nvim_colorscheme("bad name"));
    }
}
