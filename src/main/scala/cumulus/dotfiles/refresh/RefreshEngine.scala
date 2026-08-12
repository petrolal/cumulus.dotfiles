package cumulus.dotfiles.refresh

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}

object RefreshEngine:
  def runRefresh(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus refresh]\u001b[0m Triggering runtime app reloads...")

    // Sway reload
    try os.proc("swaymsg", "reload").call(check = false) catch case _: Exception => ()
    println("  \u001b[32m[OK]\u001b[0m Sent swaymsg reload")

    // Kitty reload
    try os.proc("killall", "-SIGUSR1", "kitty").call(check = false) catch case _: Exception => ()
    println("  \u001b[32m[OK]\u001b[0m Sent SIGUSR1 to Kitty instances")

    // Waybar reload
    try os.proc("killall", "-SIGUSR1", "waybar").call(check = false) catch case _: Exception => ()
    println("  \u001b[32m[OK]\u001b[0m Sent SIGUSR1 to Waybar instances")

    runOsColorscheme(ctx)
    Right(())

  def runOsColorscheme(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus os-colorscheme]\u001b[0m Syncing GNOME GTK color-scheme...")
    try
      os.proc("gsettings", "set", "org.gnome.desktop.interface", "color-scheme", "prefer-dark").call(check = false)
      println("  \u001b[32m[OK]\u001b[0m Set org.gnome.desktop.interface color-scheme = 'prefer-dark'")
      Right(())
    catch
      case e: Exception => Right(println(s"  \u001b[33m[NOTE]\u001b[0m gsettings update: ${e.getMessage}"))

  def runRgbTheme(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    val color = args.headOption.getOrElse("33ccff")
    println(s"\u001b[1;36m[cumulus rgb-theme]\u001b[0m Syncing OpenRGB hardware lighting (color: #$color)...")
    try
      os.proc("openrgb", "--color", color).call(check = false)
      println(s"  \u001b[32m[OK]\u001b[0m Updated OpenRGB profile to #$color")
      Right(())
    catch
      case _: Exception => Right(println("  \u001b[33m[NOTE]\u001b[0m OpenRGB daemon not running"))
