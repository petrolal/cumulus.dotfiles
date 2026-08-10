//! The `theme` subcommand: select a flavor + background mode and apply it live.

pub mod palette;
pub mod render;
pub mod services;
pub mod state;
pub mod wallpaper;

use crate::bail;
use crate::context::Context;
use crate::error::Result;
use crate::util::{self, basename, log};
use render::generate_configs;
use state::State;
use std::path::Path;
use wallpaper as wp;

const HELP: &str = "\
cumulus-theme — select a desktop flavor + background mode and apply it live.

Usage:
  cumulus-theme set <flavor>                              flat color (default mode)
  cumulus-theme set <flavor> --theme-default              use the flavor's tracked wallpaper
  cumulus-theme set <flavor> --preserve-background        keep current wallpaper/rotation mode
  cumulus-theme set <flavor> --wallpaper <path|filename>  static wallpaper
  cumulus-theme set <flavor> --rotate [--interval 30m]    rotate images in themes/wallpapers/
  cumulus-theme set <flavor> --flat                       force flat color mode
  cumulus-theme apply                                     re-apply the saved state
  cumulus-theme next                                      advance to the next wallpaper (rotate)
  cumulus-theme list                                      list available flavors + wallpapers
  cumulus-theme current                                   show the active flavor/mode
";

/// Entry point for `cumulus theme <args>` / `cumulus-theme <args>`.
pub fn run(ctx: &Context, args: &[String]) -> Result<()> {
    let sub = args.first().map(String::as_str).unwrap_or("");
    let rest = if args.is_empty() { &[][..] } else { &args[1..] };
    match sub {
        "set" => cmd_set(ctx, rest),
        "apply" => cmd_apply(ctx),
        "next" => cmd_next(ctx),
        "list" => cmd_list(ctx),
        "current" => cmd_current(ctx),
        "-h" | "--help" | "" => {
            print!("{HELP}");
            Ok(())
        }
        other => bail!("unknown subcommand '{other}' (set/apply/next/list/current)"),
    }
}

fn cmd_set(ctx: &Context, args: &[String]) -> Result<()> {
    let flavor = match args.first() {
        Some(f) => f.clone(),
        None => bail!(
            "usage: theme.sh set <flavor> [--wallpaper <path>|--rotate [--interval N]|--flat]"
        ),
    };
    if !wp::is_valid_flavor(ctx, &flavor) {
        bail!(
            "unknown flavor '{flavor}' — choices: {} ",
            wp::valid_flavors(ctx).join(" ")
        );
    }

    let mut mode = "flat".to_string();
    let mut wallpaper = String::new();
    let mut interval = "30m".to_string();
    let mut wallpaper_source = "flat".to_string();
    let mut preserve_background = false;
    let mut mode_explicit = false;
    let mut wallpaper_explicit = false;
    let mut theme_default_explicit = false;

    let rest = &args[1..];
    let mut i = 0;
    while i < rest.len() {
        match rest[i].as_str() {
            "--wallpaper" => {
                mode = "wallpaper".into();
                mode_explicit = true;
                wallpaper_explicit = true;
                theme_default_explicit = false;
                wallpaper = rest
                    .get(i + 1)
                    .cloned()
                    .ok_or_else(|| crate::error::Error::new("--wallpaper requires a value"))?;
                i += 2;
            }
            "--theme-default" => {
                mode = "wallpaper".into();
                wallpaper_source = "theme-default".into();
                theme_default_explicit = true;
                wallpaper_explicit = false;
                mode_explicit = true;
                i += 1;
            }
            "--rotate" => {
                mode = "rotate".into();
                mode_explicit = true;
                i += 1;
            }
            "--interval" => {
                interval = rest
                    .get(i + 1)
                    .cloned()
                    .ok_or_else(|| crate::error::Error::new("--interval requires a value"))?;
                i += 2;
            }
            "--flat" => {
                mode = "flat".into();
                mode_explicit = true;
                i += 1;
            }
            "--preserve-background" => {
                preserve_background = true;
                i += 1;
            }
            other => bail!("unknown option: {other}"),
        }
    }

    if preserve_background && !mode_explicit && ctx.state_file().is_file() {
        let s = State::load(ctx);
        mode = if s.mode.is_empty() {
            "flat".into()
        } else {
            s.mode
        };
        wallpaper = s.wallpaper;
        interval = if s.interval.is_empty() {
            "30m".into()
        } else {
            s.interval
        };
        wallpaper_source = s.wallpaper_source;
    }

    mode = wp::normalize_mode(&mode);
    wp::validate_interval(&interval)?;

    if mode == "flat" {
        wallpaper.clear();
        wallpaper_source = "flat".into();
    } else if mode == "rotate" {
        wallpaper_source = "rotate".into();
    }

    if mode == "wallpaper" && wallpaper_source == "theme-default" {
        match wp::default_wallpaper(ctx, &flavor) {
            Some(p) => wallpaper = p.to_string_lossy().into_owned(),
            None => {
                mode = "flat".into();
                wallpaper.clear();
                wallpaper_source = "flat".into();
            }
        }
    } else if mode == "wallpaper" {
        if !wallpaper_explicit && !wallpaper.is_empty() && !Path::new(&wallpaper).is_file() {
            if let Some(p) = wp::default_wallpaper(ctx, &flavor) {
                wallpaper = p.to_string_lossy().into_owned();
                wallpaper_source = "theme-default".into();
            } else {
                mode = "flat".into();
                wallpaper.clear();
                wallpaper_source = "flat".into();
            }
        }
        if mode == "wallpaper" && wallpaper.is_empty() {
            bail!("wallpaper path is empty");
        }
    }

    if mode == "wallpaper" {
        if wallpaper.is_empty() {
            bail!("wallpaper path is empty");
        }
        if !Path::new(&wallpaper).is_file() {
            let candidate = ctx.wallpapers_dir().join(&wallpaper);
            if candidate.is_file() {
                wallpaper = candidate.to_string_lossy().into_owned();
            }
        }
        if !Path::new(&wallpaper).is_file() {
            bail!(
                "wallpaper not found: {wallpaper} (put images in themes/wallpapers/ or pass a full path)"
            );
        }
        wallpaper = util::absolutize(Path::new(&wallpaper))
            .to_string_lossy()
            .into_owned();

        if theme_default_explicit {
            wallpaper_source = "theme-default".into();
        } else if wallpaper_explicit || wallpaper_source == "user" {
            wallpaper_source = "user".into();
        } else if wallpaper_source == "theme-default"
            || wp::starts_in_wallpapers_svg(ctx, &wallpaper)
        {
            wallpaper_source = "theme-default".into();
        } else {
            wallpaper_source = "user".into();
        }
    }

    if mode == "rotate" {
        let images = wp::flavor_wallpapers(ctx, &flavor);
        if images.is_empty() {
            bail!(
                "no images found in {} — add some first",
                ctx.wallpapers_dir().display()
            );
        }
        wallpaper = images[0].to_string_lossy().into_owned();
    }

    wp::validate_wallpaper_source(&mode, &wallpaper_source)?;
    // Validate the palette before touching shared state.
    palette::Palette::load(ctx, &flavor).validate(&flavor)?;

    let palette = generate_configs(ctx, &flavor, &mode, &wallpaper)?;
    State {
        flavor: flavor.clone(),
        mode: mode.clone(),
        wallpaper: wallpaper.clone(),
        wallpaper_source,
        interval: interval.clone(),
        nvim_colorscheme: palette.nvim().to_string(),
    }
    .write(ctx)?;

    if mode == "rotate" {
        services::write_rotate_units(ctx, &interval);
    } else {
        services::disable_rotate_units(ctx);
    }

    services::reload_apps(ctx);
    let suffix = if wallpaper.is_empty() {
        String::new()
    } else {
        format!(" ({})", basename(&wallpaper))
    };
    log("theme", &format!("Theme set: {flavor} / {mode}{suffix}"));
    Ok(())
}

fn cmd_apply(ctx: &Context) -> Result<()> {
    if !ctx.state_file().is_file() {
        log(
            "theme",
            "No saved theme state — applying default (oci / rotate).",
        );
        return cmd_set(ctx, &["oci".to_string(), "--rotate".to_string()]);
    }
    let mut s = State::load(ctx);
    if !wp::is_valid_flavor(ctx, &s.flavor) {
        bail!("invalid saved flavor: {}", missing_or(&s.flavor));
    }
    let saved_mode = if s.mode.is_empty() {
        "flat".to_string()
    } else {
        s.mode.clone()
    };
    s.mode = wp::normalize_mode(&saved_mode);
    if saved_mode != s.mode {
        log("theme", "warning: invalid saved mode; using flat");
        s.wallpaper.clear();
        s.wallpaper_source = "flat".into();
    }
    if s.interval.is_empty() {
        s.interval = "30m".into();
    }
    wp::validate_interval(&s.interval)?;

    match s.mode.as_str() {
        "flat" => {
            s.wallpaper.clear();
            s.wallpaper_source = "flat".into();
        }
        "rotate" => s.wallpaper_source = "rotate".into(),
        "wallpaper" if s.wallpaper_source.is_empty() => {
            s.wallpaper_source = if wp::starts_in_wallpapers_svg(ctx, &s.wallpaper) {
                "theme-default".into()
            } else {
                "user".into()
            };
        }
        _ => {}
    }

    if s.mode == "wallpaper" && !Path::new(&s.wallpaper).is_file() {
        match wp::default_wallpaper(ctx, &s.flavor) {
            Some(p) => {
                s.wallpaper = p.to_string_lossy().into_owned();
                s.wallpaper_source = "theme-default".into();
            }
            None => {
                s.mode = "flat".into();
                s.wallpaper.clear();
                s.wallpaper_source = "flat".into();
            }
        }
    } else if s.mode == "rotate" {
        let images = wp::flavor_wallpapers(ctx, &s.flavor);
        if images.is_empty() {
            s.mode = "flat".into();
            s.wallpaper.clear();
            s.wallpaper_source = "flat".into();
        } else if !Path::new(&s.wallpaper).is_file() {
            s.wallpaper = images[0].to_string_lossy().into_owned();
            s.wallpaper_source = "rotate".into();
        }
    }

    wp::validate_wallpaper_source(&s.mode, &s.wallpaper_source)?;
    let palette = generate_configs(ctx, &s.flavor, &s.mode, &s.wallpaper)?;
    s.nvim_colorscheme = palette.nvim().to_string();
    s.write(ctx)?;
    if s.mode == "rotate" {
        services::write_rotate_units(ctx, &s.interval);
    } else {
        services::disable_rotate_units(ctx);
    }
    services::reload_apps(ctx);
    log(
        "theme",
        &format!("Re-applied saved theme: {} / {}", s.flavor, s.mode),
    );
    Ok(())
}

fn cmd_next(ctx: &Context) -> Result<()> {
    if !ctx.state_file().is_file() {
        bail!("no theme set yet — run 'theme.sh set <flavor> --rotate' first");
    }
    let mut s = State::load(ctx);
    if !wp::is_valid_flavor(ctx, &s.flavor) {
        bail!("invalid saved flavor: {}", missing_or(&s.flavor));
    }
    if s.mode != "rotate" {
        bail!(
            "current mode is '{}', not rotate — nothing to advance",
            missing_or(&s.mode)
        );
    }
    if s.interval.is_empty() {
        s.interval = "30m".into();
    }
    wp::validate_interval(&s.interval)?;

    let images = wp::flavor_wallpapers(ctx, &s.flavor);
    if images.is_empty() {
        bail!("no images found in {}", ctx.wallpapers_dir().display());
    }
    let mut next_idx = 0;
    for (i, img) in images.iter().enumerate() {
        if img.to_string_lossy() == s.wallpaper {
            next_idx = (i + 1) % images.len();
            break;
        }
    }
    let next_wallpaper = images[next_idx].to_string_lossy().into_owned();

    let palette = generate_configs(ctx, &s.flavor, "rotate", &next_wallpaper)?;
    State {
        flavor: s.flavor.clone(),
        mode: "rotate".into(),
        wallpaper: next_wallpaper.clone(),
        wallpaper_source: "rotate".into(),
        interval: s.interval.clone(),
        nvim_colorscheme: palette.nvim().to_string(),
    }
    .write(ctx)?;
    services::reload_apps(ctx);
    log(
        "theme",
        &format!("Advanced wallpaper -> {}", basename(&next_wallpaper)),
    );
    Ok(())
}

fn cmd_list(ctx: &Context) -> Result<()> {
    println!("Flavors:");
    for f in wp::valid_flavors(ctx) {
        let p = palette::Palette::load(ctx, &f);
        println!("  {:<10} {}", f, p.get("THEME_LABEL"));
    }
    println!();
    println!("Wallpapers ({}):", ctx.wallpapers_dir().display());
    let images = wp::all_wallpaper_names(ctx);
    if images.is_empty() {
        println!("  (none — drop image files in themes/wallpapers/ to use --wallpaper/--rotate)");
    } else {
        for name in images {
            println!("  {name}");
        }
    }
    Ok(())
}

fn cmd_current(ctx: &Context) -> Result<()> {
    if ctx.state_file().is_file() {
        let s = State::load(ctx);
        println!("Flavor:  {}", s.flavor);
        println!("Mode:    {}", s.mode);
        let source = if s.wallpaper_source.is_empty() {
            "legacy"
        } else {
            &s.wallpaper_source
        };
        println!("Source:  {source}");
        if !s.wallpaper.is_empty() {
            println!("Image:   {}", basename(&s.wallpaper));
        }
        if s.mode == "rotate" {
            let interval = if s.interval.is_empty() {
                "30m"
            } else {
                &s.interval
            };
            println!("Interval: {interval}");
        }
    } else {
        println!("No theme set yet (default is oci / rotate).");
    }
    Ok(())
}

fn missing_or(value: &str) -> String {
    if value.is_empty() {
        "<missing>".to_string()
    } else {
        value.to_string()
    }
}
