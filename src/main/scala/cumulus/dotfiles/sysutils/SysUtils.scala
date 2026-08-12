package cumulus.dotfiles.sysutils

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}

object SysUtils:
  def runLock(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;34m[cumulus lock]\u001b[0m Locking screen via swaylock...")
    try
      os.proc("swaylock", "-f", "-c", "1e1e2e").call(check = false)
      Right(())
    catch
      case e: Exception => Left(CommandError(s"Lock failed: ${e.getMessage}"))

  def runIdle(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;34m[cumulus idle]\u001b[0m Launching swayidle daemon...")
    try
      val res = os.proc(
        "swayidle", "-w",
        "timeout", "300", "swaylock -f -c 1e1e2e",
        "timeout", "600", "swaymsg 'output * dpms off'",
        "resume", "swaymsg 'output * dpms on'"
      ).call(check = false)
      Right(())
    catch
      case e: Exception => Left(CommandError(s"Idle daemon failed: ${e.getMessage}"))

  def runScreenshot(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    val mode = args.headOption.getOrElse("full")
    val screenshotsDir = ctx.home / "Pictures" / "Screenshots"
    os.makeDir.all(screenshotsDir)
    val file = screenshotsDir / s"screenshot-${System.currentTimeMillis()}.png"

    println(s"\u001b[1;34m[cumulus screenshot]\u001b[0m Capturing $mode screenshot to $file...")
    try
      mode match
        case "region" =>
          os.proc("bash", "-c", s"grim -g \"$$(slurp)\" $file && wl-copy < $file").call(check = false)
        case _ =>
          os.proc("grim", file.toString).call(check = false)
      println(s"  \u001b[32m[OK]\u001b[0m Screenshot saved to $file")
      Right(())
    catch
      case e: Exception => Left(CommandError(s"Screenshot failed: ${e.getMessage}"))
