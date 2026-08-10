//! `cumulus-sdd` — token-efficient spec-driven development CLI for AI workflows.
//! Ports `.cumulus-sdd/bin/cumulus.js` to std Rust.

use crate::context::Context;
use crate::error::{Error, Result};
use std::env;
use std::fs;
use std::io::{self, IsTerminal, Write};
use std::path::{Path, PathBuf};
use std::process::Command;

pub fn run(ctx: &Context, args: &[String]) -> Result<()> {
    let sub = args.first().map(String::as_str).unwrap_or("");
    match sub {
        "init" => cmd_init(ctx),
        "new" => {
            let story_id = args.get(1).map(String::as_str).unwrap_or("");
            cmd_new(ctx, story_id)
        }
        "verify" => cmd_verify(ctx),
        "-h" | "--help" | "" => {
            println!("{HELP_TEXT}");
            Ok(())
        }
        other => {
            eprintln!("Unknown sdd command: '{other}'");
            Err(Error::with_code("", 1))
        }
    }
}

fn cmd_init(ctx: &Context) -> Result<()> {
    println!(
        "\x1b[1;34m[cumulus-sdd]\x1b[0m Initializing sdd in {}",
        ctx.home.display()
    );

    let cwd = env::current_dir().unwrap_or_else(|_| ctx.dotfiles_dir.clone());
    let target_framework = cwd.join(".cumulus-sdd");
    let target_sdd = cwd.join("docs/sdd");

    let source_framework = ctx.dotfiles_dir.join(".cumulus-sdd");

    for dir_name in ["agents", "templates"] {
        let src = source_framework.join(dir_name);
        let dst = target_framework.join(dir_name);
        if src.is_dir() {
            copy_dir_all(&src, &dst)?;
            println!("  \x1b[32mOK\x1b[0m   .cumulus-sdd/{dir_name}/");
        }
    }

    fs::create_dir_all(&target_sdd)?;
    let gitkeep = target_sdd.join(".gitkeep");
    if !gitkeep.exists() {
        let _ = fs::write(&gitkeep, "");
    }
    println!("  \x1b[32mOK\x1b[0m   docs/sdd/");
    println!("\x1b[1;34m[cumulus-sdd]\x1b[0m Done. Next: `cumulus sdd new <story-id>` to create your first story.");

    Ok(())
}

fn cmd_new(ctx: &Context, story_id: &str) -> Result<()> {
    let id = story_id.trim();
    if id.is_empty()
        || !id
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '.' || c == '-' || c == '_')
    {
        eprintln!(
            "invalid story id '{story_id}' — use letters, digits, dot, dash, underscore only."
        );
        return Err(Error::with_code("", 1));
    }

    let cwd = env::current_dir().unwrap_or_else(|_| ctx.dotfiles_dir.clone());
    let sdd_dir = cwd.join("docs/sdd");
    fs::create_dir_all(&sdd_dir)?;

    let out_path = sdd_dir.join(format!("story-{id}.md"));
    if out_path.exists() {
        eprintln!("story already exists: {}", out_path.display());
        return Err(Error::with_code("", 1));
    }

    let local_template = cwd.join(".cumulus-sdd/templates/story-template.md");
    let global_template = ctx
        .dotfiles_dir
        .join(".cumulus-sdd/templates/story-template.md");
    let template_path = if local_template.is_file() {
        local_template
    } else {
        global_template
    };

    let template_content = fs::read_to_string(&template_path).map_err(|_| {
        Error::new(format!(
            "story template not found at {}. Run `cumulus sdd init` first.",
            template_path.display()
        ))
    })?;

    let is_tty = io::stdin().is_terminal();
    let mut title = id.to_string();
    let mut intent = String::new();
    let mut code_map = String::new();

    if is_tty {
        print!("Story title: ");
        let _ = io::stdout().flush();
        let mut line = String::new();
        let _ = io::stdin().read_line(&mut line);
        if !line.trim().is_empty() {
            title = line.trim().to_string();
        }

        print!("Intent (1-2 sentences): ");
        let _ = io::stdout().flush();
        line.clear();
        let _ = io::stdin().read_line(&mut line);
        intent = line.trim().to_string();

        print!("Primary file to touch (path): ");
        let _ = io::stdout().flush();
        line.clear();
        let _ = io::stdin().read_line(&mut line);
        code_map = line.trim().to_string();
    } else {
        println!("  \x1b[33mWARN\x1b[0m no TTY detected — using defaults; edit the story to fill in details.");
    }

    let today = Command::new("date")
        .arg("+%Y-%m-%d")
        .output()
        .ok()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_else(|| "2026-08-10".to_string());

    let mut body = template_content
        .replace("STORY-<ID>", &format!("STORY-{id}"))
        .replace("created: YYYY-MM-DD", &format!("created: {today}"))
        .replace("# Story <ID>: <TITLE>", &format!("# Story {id}: {title}"));

    if !intent.is_empty() {
        body = body.replace(
            "## Intent\n<One or two sentences. What this unit of work delivers.>",
            &format!("## Intent\n{intent}"),
        );
    }
    if !code_map.is_empty() {
        body = body.replace(
            "- `<path>` — <role / why relevant>",
            &format!("- `{code_map}` — primary touch point"),
        );
    }

    fs::write(&out_path, body)?;
    println!(
        "\x1b[1;34m[cumulus-sdd]\x1b[0m Created {}",
        out_path.display()
    );
    println!("\x1b[1;34m[cumulus-sdd]\x1b[0m Feed ONLY this file to your coding agent to keep context minimal.");

    Ok(())
}

fn cmd_verify(ctx: &Context) -> Result<()> {
    let cwd = env::current_dir().unwrap_or_else(|_| ctx.dotfiles_dir.clone());
    let sdd_dir = cwd.join("docs/sdd");
    println!(
        "\x1b[1;34m[cumulus-sdd]\x1b[0m Verifying specs in {}",
        sdd_dir.display()
    );

    if !sdd_dir.is_dir() {
        eprintln!("docs/sdd not found — run `cumulus sdd init` first.");
        return Err(Error::with_code("", 1));
    }

    let mut entries = Vec::new();
    if let Ok(read) = fs::read_dir(&sdd_dir) {
        for entry in read.flatten() {
            let path = entry.path();
            if path.extension().and_then(|e| e.to_str()) == Some("md") {
                if let Some(name) = path.file_name().and_then(|n| n.to_str()) {
                    entries.push((name.to_string(), path));
                }
            }
        }
    }
    entries.sort_by(|a, b| a.0.cmp(&b.0));

    if entries.is_empty() {
        println!("  \x1b[33mWARN\x1b[0m no .md specs found in docs/sdd/.");
        println!("\x1b[1;34m[cumulus-sdd]\x1b[0m Verify result: nothing to check.");
        return Ok(());
    }

    let mut failures = 0;
    for (name, path) in &entries {
        let content = fs::read_to_string(path).unwrap_or_default();
        let mut problems = Vec::new();

        if !content.starts_with("---\n") {
            problems.push("missing YAML frontmatter");
        }
        if !content.contains("\n# ") && !content.starts_with("# ") {
            problems.push("missing H1 title");
        }
        if !content.contains("## Acceptance Criteria") {
            problems.push("missing '## Acceptance Criteria' section");
        }
        if !content.contains("- [ ]") && !content.contains("- [x]") && !content.contains("- [X]") {
            problems.push("no acceptance-criteria checkboxes (\"- [ ]\" / \"- [x]\")");
        }

        let unchecked = content.matches("- [ ]").count();
        let checked = content.matches("- [x]").count() + content.matches("- [X]").count();

        if problems.is_empty() {
            println!("  \x1b[32mOK\x1b[0m   {name} — {checked} done / {unchecked} open");
        } else {
            failures += 1;
            println!("  \x1b[31mFAIL\x1b[0m {name} — {}", problems.join("; "));
        }
    }

    println!();
    if failures > 0 {
        eprintln!("{failures} spec(s) failed verification.");
        return Err(Error::with_code("", 1));
    }

    println!(
        "\x1b[1;34m[cumulus-sdd]\x1b[0m Verify result: all {} spec(s) conform.",
        entries.len()
    );
    Ok(())
}

fn copy_dir_all(src: &Path, dst: &Path) -> io::Result<()> {
    fs::create_dir_all(dst)?;
    for entry in fs::read_dir(src)? {
        let entry = entry?;
        let ty = entry.file_type()?;
        if ty.is_dir() {
            copy_dir_all(&entry.path(), &dst.join(entry.file_name()))?;
        } else {
            fs::copy(entry.path(), dst.join(entry.file_name()))?;
        }
    }
    Ok(())
}

const HELP_TEXT: &str = "\
cumulus-sdd — token-efficient spec-driven development for AI workflows.

Usage:
  cumulus sdd <command> [args...]
  cumulus-sdd <command> [args...]

Commands:
  init            Inject .cumulus-sdd/ (agents + templates) and docs/sdd/ into current project
  new <story-id>  Instantiate a new story spec from template
  verify          Validate that docs/sdd/*.md files have required headers & checkboxes
";
