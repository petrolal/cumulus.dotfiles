package cumulus.dotfiles.autotiling

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}

object AutotilingDaemon:
  def run(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    ctx.swaySocket match
      case None =>
        Left(CommandError("SWAYSOCK environment variable is not set. Sway autotiling daemon requires active Sway session."))
      case Some(sock) =>
        println(s"\u001b[1;36m[cumulus autotiling]\u001b[0m Starting Sway multi-monitor Fibonacci autotiling daemon (socket: $sock)...")
        try
          autoSplitFocusedWindow()
          println("  \u001b[32m[OK]\u001b[0m Multi-monitor autotiling active.")
          Right(())
        catch
          case e: Exception => Left(CommandError(s"Autotiling daemon failed: ${e.getMessage}"))

  def autoSplitFocusedWindow(): Unit =
    try
      val res = os.proc("swaymsg", "-t", "get_tree").call(check = false)
      if res.exitCode == 0 then
        val json = ujson.read(res.out.text())
        val (width, height, isFloating) = findFocusedWindowNode(json)
        if !isFloating && width > 0 && height > 0 then
          val splitCmd = if width > height then "split h" else "split v"
          os.proc("swaymsg", splitCmd).call(check = false)
    catch
      case _: Exception => ()

  private def findFocusedWindowNode(node: ujson.Value): (Int, Int, Boolean) =
    try
      val isFloatingNode = node.obj.get("type").exists(_.str == "floating_con")
      if node.obj.get("focused").exists(_.bool) then
        val rect = node.obj("rect")
        (rect("width").num.toInt, rect("height").num.toInt, isFloatingNode)
      else
        val tiledNodes = node.obj.get("nodes").map(_.arr).getOrElse(Vector.empty)
        val floatingNodes = node.obj.get("floating_nodes").map(_.arr).getOrElse(Vector.empty)
        val allChildren = tiledNodes ++ floatingNodes

        allChildren.map(findFocusedWindowNode).find(_._1 > 0).getOrElse((0, 0, false))
    catch
      case _: Exception => (0, 0, false)
