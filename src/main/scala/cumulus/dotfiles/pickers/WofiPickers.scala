package cumulus.dotfiles.pickers

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}
import cumulus.dotfiles.theme.ThemeEngine

object WofiPickers:
  def runThemePicker(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    println("\u001b[1;35m[cumulus theme-picker]\u001b[0m Launching Wofi GUI theme picker...")
    val themes = cumulus.dotfiles.theme.Palette.listAll(ctx)
    val inputList = themes.mkString("\n")

    try
      // Step 1: Select Theme
      val resTheme = os.proc(
        "wofi", "--show", "dmenu",
        "--prompt", "Select Theme",
        "--width", "400",
        "--lines", "10",
        "--cache-file", "/dev/null"
      ).call(stdin = inputList, check = false)

      val selectedTheme = resTheme.out.text().trim
      if selectedTheme.isEmpty then return Right(())

      println(s"  \u001b[32m[OK]\u001b[0m Selected theme '$selectedTheme'")

      // Step 2: Select Wallpaper Mode
      val modes = Seq("1. Static Wallpaper", "2. Rotate Wallpapers (30m)")
      val resMode = os.proc(
        "wofi", "--show", "dmenu",
        "--prompt", s"Wallpaper mode for '$selectedTheme'",
        "--width", "450",
        "--lines", "4",
        "--cache-file", "/dev/null"
      ).call(stdin = modes.mkString("\n"), check = false)

      val selectedModeStr = resMode.out.text().trim
      val (mode, interval) = if selectedModeStr.contains("Rotate") then
        ("rotate", "30m")
      else
        ("wallpaper", "30m")

      ThemeEngine.applyTheme(ctx, selectedTheme, mode = mode, customWallpaper = None, interval = interval)
    catch
      case e: Exception => Left(CommandError(s"Wofi theme-picker failed: ${e.getMessage}"))

  def runWhichkey(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    println("\u001b[1;35m[cumulus whichkey]\u001b[0m Displaying Sway keybindings cheatsheet...")
    val keybindingsList = resolveSwayKeybindings(ctx)
    val inputList = if keybindingsList.nonEmpty then keybindingsList.mkString("\n") else defaultKeybindings.mkString("\n")

    try
      val proc = os.proc(
        "wofi", "--show", "dmenu",
        "--prompt", "which-key",
        "--width", "750",
        "--lines", "22",
        "--cache-file", "/dev/null"
      ).spawn(stdin = inputList)
      Right(())
    catch
      case e: Exception => Left(CommandError(s"Wofi whichkey failed: ${e.getMessage}"))

  private def resolveSwayKeybindings(ctx: Context): Seq[String] =
    try
      val configContent = getSwayConfigContent(ctx)
      if configContent.nonEmpty then expandBindings(configContent) else Nil
    catch
      case _: Exception => Nil

  private def getSwayConfigContent(ctx: Context): String =
    try
      val res = os.proc("swaymsg", "-t", "get_config").call(check = false)
      if res.exitCode == 0 then
        val json = ujson.read(res.out.text())
        json.obj.get("config").map(_.str).getOrElse("")
      else
        val configFile = ctx.configDir / "sway" / "config"
        if os.exists(configFile) then os.read(configFile) else ""
    catch
      case _: Exception =>
        val configFile = ctx.configDir / "sway" / "config"
        if os.exists(configFile) then os.read(configFile) else ""

  private def expandBindings(config: String): Seq[String] =
    var varDefs = Map.empty[String, String]
    var bindings = Vector.empty[String]

    for line <- config.linesIterator do
      val trimmed = line.trim
      if !trimmed.startsWith("#") && trimmed.nonEmpty then
        if trimmed.startsWith("set ") then
          val parts = trimmed.split("\\s+", 3)
          if parts.length >= 3 && parts(1).startsWith("$") then
            varDefs += (parts(1) -> parts(2).replace("\"", ""))
        else if trimmed.startsWith("bindsym ") || trimmed.startsWith("bindcode ") then
          var bindingLine = trimmed.stripPrefix("bindsym ").stripPrefix("bindcode ").trim
          bindingLine = bindingLine.replaceAll("--[a-z-]+", "").trim
          for (varName, varVal) <- varDefs do
            bindingLine = bindingLine.replace(varName, varVal)
          val parts = bindingLine.split("\\s+", 2)
          if parts.length == 2 then
            val key = parts(0)
            val action = parts(1)
            bindings = bindings :+ f"$key%-24s → $action"
          else
            bindings = bindings :+ bindingLine

    bindings

  private val defaultKeybindings = Seq(
    "Mod4+Return              → exec kitty",
    "Mod4+d                   → exec wofi --show drun",
    "Mod4+Shift+q             → kill",
    "Mod4+Shift+e             → exec swaynag -t warning -m 'Exit Sway?'",
    "Mod4+f                   → fullscreen toggle",
    "Mod4+v                   → splitv",
    "Mod4+b                   → splith",
    "Mod4+Shift+l             → exec cumulus-lock",
    "Mod4+Shift+p             → exec cumulus-theme-picker",
    "Mod4+Shift+s             → exec cumulus-screenshot"
  )
