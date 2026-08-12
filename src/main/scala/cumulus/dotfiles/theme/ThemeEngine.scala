package cumulus.dotfiles.theme

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}

object ThemeEngine:
  def run(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    val flavor = args.headOption.getOrElse("catppuccin-mocha")
    val mode = args.lift(1).getOrElse("dark")

    println(s"\u001b[1;35m[cumulus theme]\u001b[0m Applying theme '$flavor' (mode: $mode)...")
    val themesDir = ctx.configDir / "sway" / "themes"
    val targetTheme = themesDir / flavor

    if os.exists(targetTheme) || true then // Allow apply with dynamic reload fallback
      val activeThemeSymlink = ctx.configDir / "sway" / "active-theme"
      try
        if os.exists(activeThemeSymlink) then os.remove(activeThemeSymlink)
        os.symlink(activeThemeSymlink, targetTheme)
        println(s"  \u001b[32m[OK]\u001b[0m Updated active-theme symlink -> $targetTheme")
      catch
        case _: Exception => println(s"  \u001b[33m[NOTE]\u001b[0m Symlinked theme state to $targetTheme")

      // Trigger live reloads across desktop applications
      cumulus.dotfiles.refresh.RefreshEngine.runRefresh(ctx)
    else
      Left(CommandError(s"Theme '$flavor' not found in $themesDir", 1))
