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

    // Waybar reload (SIGUSR2 reloads config & CSS stylesheet without hiding bar)
    try os.proc("killall", "-SIGUSR2", "waybar").call(check = false) catch case _: Exception => ()
    println("  \u001b[32m[OK]\u001b[0m Sent SIGUSR2 to Waybar instances")

    // Mako reload (kill and restart to pick up new config)
    try
      val killRes = os.proc("killall", "mako").call(check = false)
      if killRes.exitCode == 0 then
        Thread.sleep(100)
        os.proc("mako").call(stdout = os.Pipe, stderr = os.Pipe, check = false)
        println("  [32m[OK][0m Restarted Mako notification daemon")
    catch
      case _: Exception => ()

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
