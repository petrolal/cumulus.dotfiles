//! Flavor discovery, wallpaper selection, and mode/interval validation.

use crate::bail;
use crate::collate;
use crate::context::Context;
use crate::error::Result;
use std::ffi::OsStr;
use std::path::{Path, PathBuf};

/// `^[A-Za-z0-9_-]+$`
pub fn is_flavor_name(v: &str) -> bool {
    !v.is_empty()
        && v.bytes()
            .all(|c| c.is_ascii_alphanumeric() || c == b'_' || c == b'-')
}

/// All flavors (basenames of `themes/palettes/*.sh`), locale-sorted.
pub fn valid_flavors(ctx: &Context) -> Vec<String> {
    let mut out = Vec::new();
    if let Ok(entries) = std::fs::read_dir(ctx.palettes_dir()) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.extension() == Some(OsStr::new("sh")) {
                if let Some(stem) = path.file_stem().and_then(OsStr::to_str) {
                    out.push(stem.to_string());
                }
            }
        }
    }
    collate::sort_strings(&mut out);
    out
}

/// Whether `flavor` is a well-formed name with an existing palette file.
pub fn is_valid_flavor(ctx: &Context, flavor: &str) -> bool {
    is_flavor_name(flavor) && ctx.palettes_dir().join(format!("{flavor}.sh")).is_file()
}

/// The flavor's tracked default wallpaper (`themes/wallpapers/<flavor>.svg`).
pub fn default_wallpaper(ctx: &Context, flavor: &str) -> Option<PathBuf> {
    let candidate = ctx.wallpapers_dir().join(format!("{flavor}.svg"));
    candidate.is_file().then_some(candidate)
}

/// Whether `path` has a supported image extension.
pub fn is_image(path: &Path) -> bool {
    matches!(
        path.extension().and_then(OsStr::to_str),
        Some("jpg" | "jpeg" | "png" | "webp" | "svg")
    )
}

/// Images whose basename starts with `<flavor>` followed by `.`, `_` or `-`;
/// falls back to every image if none match. Sorted like the shell glob.
pub fn flavor_wallpapers(ctx: &Context, flavor: &str) -> Vec<PathBuf> {
    let mut all: Vec<PathBuf> = Vec::new();
    if let Ok(entries) = std::fs::read_dir(ctx.wallpapers_dir()) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_file() && is_image(&path) {
                all.push(path);
            }
        }
    }
    collate::sort_paths(&mut all);
    let matched: Vec<PathBuf> = all
        .iter()
        .filter(|path| {
            path.file_name()
                .and_then(OsStr::to_str)
                .and_then(|name| name.strip_prefix(flavor))
                .and_then(|rest| rest.chars().next())
                .map(|c| c == '.' || c == '_' || c == '-')
                .unwrap_or(false)
        })
        .cloned()
        .collect();
    if matched.is_empty() {
        all
    } else {
        matched
    }
}

/// All image basenames in the wallpaper pool, locale-sorted.
pub fn all_wallpaper_names(ctx: &Context) -> Vec<String> {
    let mut images: Vec<String> = Vec::new();
    if let Ok(entries) = std::fs::read_dir(ctx.wallpapers_dir()) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_file() && is_image(&path) {
                if let Some(name) = path.file_name().and_then(OsStr::to_str) {
                    images.push(name.to_string());
                }
            }
        }
    }
    collate::sort_strings(&mut images);
    images
}

/// Clamp a mode string to a known value (`flat`/`wallpaper`/`rotate`).
pub fn normalize_mode(mode: &str) -> String {
    match mode {
        "flat" | "wallpaper" | "rotate" => mode.to_string(),
        _ => "flat".to_string(),
    }
}

/// Validate the (mode, source) pairing.
pub fn validate_wallpaper_source(mode: &str, source: &str) -> Result<()> {
    let ok = matches!(
        (mode, source),
        ("flat", "flat")
            | ("wallpaper", "user")
            | ("wallpaper", "theme-default")
            | ("rotate", "rotate")
    );
    if !ok {
        bail!("invalid wallpaper source '{source}' for mode '{mode}'");
    }
    Ok(())
}

/// `^[1-9][0-9]*(ms|us|s|m|h|d|w)$`
pub fn is_valid_interval(v: &str) -> bool {
    let digits_end = v.find(|c: char| !c.is_ascii_digit()).unwrap_or(v.len());
    let (digits, suffix) = v.split_at(digits_end);
    if digits.is_empty() || digits.starts_with('0') {
        return false;
    }
    matches!(suffix, "ms" | "us" | "s" | "m" | "h" | "d" | "w")
}

/// Validate a rotation interval, returning the shell error message on failure.
pub fn validate_interval(interval: &str) -> Result<()> {
    if !is_valid_interval(interval) {
        bail!("invalid rotation interval: {interval} (use values such as 30m or 1h)");
    }
    Ok(())
}

/// Single-quote a value for safe embedding in the sway `swaybg` exec line.
pub fn sway_shell_arg(value: &str) -> Result<String> {
    if value.contains('\n') || value.contains('\r') {
        bail!("wallpaper paths cannot contain newlines");
    }
    Ok(format!("'{}'", value.replace('\'', "'\\''")))
}

/// Whether a wallpaper path is a tracked default (`<wallpapers>/*.svg`).
pub fn starts_in_wallpapers_svg(ctx: &Context, wallpaper: &str) -> bool {
    let prefix = format!("{}/", ctx.wallpapers_dir().display());
    wallpaper.starts_with(&prefix) && wallpaper.ends_with(".svg")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn interval_validation() {
        assert!(is_valid_interval("30m"));
        assert!(is_valid_interval("1h"));
        assert!(is_valid_interval("500ms"));
        assert!(!is_valid_interval("0m"));
        assert!(!is_valid_interval("30"));
        assert!(!is_valid_interval("m"));
        assert!(!is_valid_interval("30y"));
    }

    #[test]
    fn shell_arg_quotes_single_quotes() {
        assert_eq!(sway_shell_arg("a'b").unwrap(), "'a'\\''b'");
        assert!(sway_shell_arg("bad\nname").is_err());
    }

    #[test]
    fn mode_normalisation() {
        assert_eq!(normalize_mode("rotate"), "rotate");
        assert_eq!(normalize_mode("bogus"), "flat");
    }
}
