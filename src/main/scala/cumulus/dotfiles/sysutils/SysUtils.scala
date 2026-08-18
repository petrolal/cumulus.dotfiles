package cumulus.dotfiles.sysutils

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}
import cumulus.dotfiles.theme.ThemeEngine

object SysUtils:
  def runLock(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;34m[cumulus lock]\u001b[0m Locking screen via swaylock...")
    val lockConfigFile = ctx.configDir / "swaylock" / "config"
    try
      val cmd = if os.exists(lockConfigFile) then
        Seq("swaylock", "-f", "--config", lockConfigFile.toString)
      else
        val palette = ThemeEngine.getActivePalette(ctx)
        val baseHex = palette.base.stripPrefix("#")
        Seq("swaylock", "-f", "-c", baseHex)
      os.proc(cmd).call(check = false)
      Right(())
    catch
      case e: Exception => Left(CommandError(s"Lock failed: ${e.getMessage}"))

  def runIdle(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;34m[cumulus idle]\u001b[0m Launching swayidle daemon...")
    val lockConfigFile = ctx.configDir / "swaylock" / "config"
    val lockCmd = if os.exists(lockConfigFile) then
      s"swaylock -f --config $lockConfigFile"
    else
      "swaylock -f -c 1e1e2e"

    try
      val res = os.proc(
        "swayidle", "-w",
        "timeout", "300", lockCmd,
        "timeout", "600", "swaymsg 'output * dpms off'",
        "resume", "swaymsg 'output * dpms on'",
        "timeout", "900", "systemctl suspend",
        "before-sleep", lockCmd
      ).call(check = false)
      Right(())
    catch
      case e: Exception => Left(CommandError(s"Idle daemon failed: ${e.getMessage}"))

  def runScreenshot(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    val mode = args.headOption.getOrElse("region")

    if mode != "full" && mode != "region" && mode != "window" then
      System.err.println("Usage: cumulus-screenshot {full|region|window}")
      return Left(CommandError("Usage: cumulus-screenshot {full|region|window}", 1))

    val screenshotsDir = ctx.home / "Pictures" / "Screenshots"
    os.makeDir.all(screenshotsDir)
    val timestamp = os.proc("date", "+%Y-%m-%d_%H-%M-%S").call(check = false).out.text().trim
    val file = screenshotsDir / s"$timestamp.png"

    println(s"\u001b[1;34m[cumulus screenshot]\u001b[0m Capturing $mode screenshot to $file...")

    try
      val captureRes = mode match
        case "full" =>
          os.proc("grim", file.toString).call(check = false)
        case "region" =>
          val slurpRes = os.proc("slurp").call(
            check = false,
            stdin = os.Inherit,
            stdout = os.Pipe,
            stderr = os.Inherit
          )
          if slurpRes.exitCode == 0 && slurpRes.out.text().trim.nonEmpty then
            val geom = slurpRes.out.text().trim
            os.proc("grim", "-g", geom, file.toString).call(check = false)
          else
            notifyDesktop("Cancelled", "Screenshot region selection cancelled.")
            return Right(())
        case "window" =>
          getFocusedWindowGeometry() match
            case Some(geom) =>
              os.proc("grim", "-g", geom, file.toString).call(check = false)
            case None =>
              notifyDesktop("Failed", "No focused window found.")
              return Left(CommandError("No focused window found", 1))

      if captureRes.exitCode == 0 && os.exists(file) then
        // Copy screenshot image bytes to wl-copy clipboard if available
        try
          if isCommandAvailable("wl-copy") then
            os.proc("wl-copy").call(stdin = os.read.bytes(file), check = false)
        catch
          case _: Exception => ()

        notifyDesktop("Screenshot Saved", s"Saved to ${file.toString} (copied to clipboard)")
        println(s"  \u001b[32m[OK]\u001b[0m Saved to $file (copied to clipboard)")
        Right(())
      else
        Left(CommandError("grim screenshot capture failed", 1))
    catch
      case e: Exception => Left(CommandError(s"Screenshot failed: ${e.getMessage}"))

  private def getFocusedWindowGeometry(): Option[String] =
    try
      val res = os.proc("swaymsg", "-t", "get_tree").call(check = false)
      if res.exitCode == 0 then
        val json = ujson.read(res.out.text())
        findFocusedNodeGeometry(json)
      else None
    catch
      case _: Exception => None

  private def findFocusedNodeGeometry(node: ujson.Value): Option[String] =
    try
      if node.obj.get("focused").exists(_.bool) then
        val rect = node.obj("rect")
        val x = rect("x").num.toInt
        val y = rect("y").num.toInt
        val w = rect("width").num.toInt
        val h = rect("height").num.toInt
        Some(s"$x,$y ${w}x$h")
      else
        val tiledNodes = node.obj.get("nodes").map(_.arr).getOrElse(Vector.empty)
        val floatingNodes = node.obj.get("floating_nodes").map(_.arr).getOrElse(Vector.empty)
        (tiledNodes ++ floatingNodes).flatMap(findFocusedNodeGeometry).headOption
    catch
      case _: Exception => None

  private def notifyDesktop(title: String, body: String): Unit =
    try
      if isCommandAvailable("notify-send") then
        val escapedTitle = title.replace("\\", "\\\\").replace("\"", "\\\"")
        val escapedBody = body.replace("\\", "\\\\").replace("\"", "\\\"")
        os.proc("notify-send", "-u", "normal", "-t", "4000", "-a", "cumulus", escapedTitle, escapedBody).call(check = false)
    catch
      case _: Exception => () // Silently fail if notification daemon unavailable

  def runCalendar(ctx: Context): Either[CumulusError, Unit] =
    if isCommandAvailable("swaync-client") && isProcessRunning("swaync") then
      try
        os.proc("swaync-client", "-t", "-sw").call(check = false)
        Right(())
      catch
        case _: Exception => runFallbackCalendar(ctx)
    else
      runFallbackCalendar(ctx)

  private def isProcessRunning(name: String): Boolean =
    try os.proc("pgrep", "-x", name).call(check = false).exitCode == 0 catch case _: Exception => false

  private def runFallbackCalendar(ctx: Context): Either[CumulusError, Unit] =
    try
      if isCommandAvailable("kitty") then
        os.proc(
          "kitty",
          "--class=cumulus-calendar",
          "--title=Calendar",
          "-o", "font_size=15",
          "-o", "remember_window_size=no",
          "-o", "initial_window_width=680",
          "-o", "initial_window_height=440",
          "sh", "-c", "cal -3; echo ''; read -n 1 -s -r -p '  [Press any key or Escape to close]' || true"
        ).spawn()
        Right(())
      else
        println("  \u001b[33m[NOTE]\u001b[0m Calendar tool not available.")
        Right(())
    catch
      case e: Exception => Left(CommandError(s"Calendar popup failed: ${e.getMessage}"))

  private def isCommandAvailable(cmd: String): Boolean =
    try os.proc("which", cmd).call(check = false).exitCode == 0 catch case _: Exception => false
