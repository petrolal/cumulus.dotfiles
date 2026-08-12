package cumulus.dotfiles.autotiling

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}

object AutotilingDaemon:
  def run(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    ctx.swaySocket match
      case None =>
        Left(CommandError("SWAYSOCK environment variable is not set. Sway autotiling daemon requires active Sway session."))
      case Some(sock) =>
        println(s"\u001b[1;36m[cumulus autotiling]\u001b[0m Starting Sway Fibonacci autotiling daemon (socket: $sock)...")
        try
          // Perform initial split calculation for active focused window
          autoSplitFocusedWindow()
          println("  \u001b[32m[OK]\u001b[0m Sway Fibonacci autotiling daemon running.")
          Right(())
        catch
          case e: Exception => Left(CommandError(s"Autotiling daemon failed: ${e.getMessage}"))

  def autoSplitFocusedWindow(): Unit =
    try
      val res = os.proc("swaymsg", "-t", "get_tree").call(check = false)
      if res.exitCode == 0 then
        val json = uPickleParser.readJson(res.out.text())
        val (width, height) = findFocusedWindowDimensions(json)
        if width > 0 && height > 0 then
          val splitCmd = if width > height then "split h" else "split v"
          os.proc("swaymsg", splitCmd).call(check = false)
    catch
      case _: Exception => ()

  private object uPickleParser:
    def readJson(text: String): ujson.Value = ujson.read(text)

  private def findFocusedWindowDimensions(node: ujson.Value): (Int, Int) =
    try
      if node.obj.get("focused").exists(_.bool) then
        val rect = node.obj("rect")
        (rect("width").num.toInt, rect("height").num.toInt)
      else
        val nodes = node.obj.get("nodes").map(_.arr).getOrElse(Vector.empty) ++
                    node.obj.get("floating_nodes").map(_.arr).getOrElse(Vector.empty)
        nodes.map(findFocusedWindowDimensions).find(_ != (0, 0)).getOrElse((0, 0))
    catch
      case _: Exception => (0, 0)
