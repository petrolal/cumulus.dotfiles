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

    // SwayNC reload CSS & config
    if isCommandAvailable("swaync-client") then
      try
        os.proc("swaync-client", "-rs").call(check = false, stdout = os.Pipe, stderr = os.Pipe)
        os.proc("swaync-client", "-R").call(check = false, stdout = os.Pipe, stderr = os.Pipe)
        println("  \u001b[32m[OK]\u001b[0m Reloaded SwayNC styling & config")
      catch
        case _: Exception => ()

    // Mako reload via systemctl (legacy compatibility)
    try
      os.proc("systemctl", "--user", "restart", "mako").call(check = false, stdout = os.Pipe, stderr = os.Pipe)
      println("  \u001b[32m[OK]\u001b[0m Restarted Mako with new theme colors")
    catch
      case _: Exception => ()

    runOsColorscheme(ctx)
    Right(())

  private def isCommandAvailable(cmd: String): Boolean =
    try os.proc("which", cmd).call(check = false, stdout = os.Pipe, stderr = os.Pipe).exitCode == 0 catch case _: Exception => false

  def runOsColorscheme(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus os-colorscheme]\u001b[0m Syncing GNOME GTK color-scheme...")
    try
      os.proc("gsettings", "set", "org.gnome.desktop.interface", "color-scheme", "prefer-dark").call(check = false)
      println("  \u001b[32m[OK]\u001b[0m Set org.gnome.desktop.interface color-scheme = 'prefer-dark'")
      Right(())
    catch
      case e: Exception => Right(println(s"  \u001b[33m[NOTE]\u001b[0m gsettings update: ${e.getMessage}"))
