package polyomino.dotfiles.pickers

import polyomino.dotfiles.context.Context
import polyomino.dotfiles.error.{CommandError, PolyominoError}
import polyomino.dotfiles.theme.ThemeEngine

object WofiPickers:
  def runThemePicker(ctx: Context, args: List[String]): Either[PolyominoError, Unit] =
    // Toggle behavior: check if theme picker is already open
    try
      val checkRes = os.proc("pgrep", "-f", "wofi.*--prompt.*Theme").call(check = false)
      if checkRes.exitCode == 0 then
        val pids = checkRes.out.text().trim.split("\\s+").filter(_.nonEmpty)
        for pid <- pids do
          try os.proc("kill", pid).call(check = false) catch case _: Exception => ()
        return Right(())
    catch
      case _: Exception => ()

    println("\u001b[1;35m[polyomino theme-picker]\u001b[0m Launching Wofi GUI theme picker...")
    val themes = polyomino.dotfiles.theme.Palette.listAll(ctx)
    val inputList = themes.map(escapeMarkup).mkString("\n")

    val wofiConfigFile = ctx.configDir / "wofi" / "config"
    val wofiStyleFile = ctx.configDir / "wofi" / "style.css"

    try
      // Step 1: Select Theme
      val themeArgs = Seq("wofi")
        ++ (if os.exists(wofiConfigFile) then Seq("--conf", wofiConfigFile.toString) else Seq.empty)
        ++ Seq(
          "--show", "dmenu",
          "--prompt", "Select Theme",
          "--width", "560",
          "--lines", "3",
          "--columns", "2",
          "--insensitive",
          "--cache-file", "/dev/null"
        ) ++ (if os.exists(wofiStyleFile) then Seq("--style", wofiStyleFile.toString) else Seq.empty)
      val shellableThemeArgs: Seq[os.Shellable] = themeArgs.map(s => (s: os.Shellable))
      val resTheme = os.proc(shellableThemeArgs*).call(stdin = inputList, check = false)

      val selectedTheme = resTheme.out.text().trim
      if selectedTheme.isEmpty then return Right(())

      println(s"  \u001b[32m[OK]\u001b[0m Selected theme '$selectedTheme'")

      // Step 2: Select Wallpaper Mode
      val modes = Seq("1. Static Wallpaper", "2. Rotate Wallpapers (30m)")
      val modeArgs = Seq("wofi")
        ++ (if os.exists(wofiConfigFile) then Seq("--conf", wofiConfigFile.toString) else Seq.empty)
        ++ Seq(
          "--show", "dmenu",
          "--prompt", s"Wallpaper mode for '$selectedTheme'",
          "--width", "560",
          "--lines", "2",
          "--columns", "2",
          "--insensitive",
          "--cache-file", "/dev/null"
        ) ++ (if os.exists(wofiStyleFile) then Seq("--style", wofiStyleFile.toString) else Seq.empty)
      val shellableModeArgs: Seq[os.Shellable] = modeArgs.map(s => (s: os.Shellable))
      val resMode = os.proc(shellableModeArgs*).call(stdin = modes.mkString("\n"), check = false)

      val selectedModeStr = resMode.out.text().trim
      val (mode, interval) = if selectedModeStr.contains("Rotate") then
        ("rotate", "30m")
      else
        ("wallpaper", "30m")

      ThemeEngine.applyTheme(ctx, selectedTheme, mode = mode, customWallpaper = None, interval = interval)
    catch
      case e: Exception => Left(CommandError(s"Wofi theme-picker failed: ${e.getMessage}"))

  def runWhichkey(ctx: Context, args: List[String]): Either[PolyominoError, Unit] =
    // Toggle behavior: check if whichkey wofi is already running
    try
      val checkRes = os.proc("pgrep", "-f", "wofi.*--prompt.*which-key").call(check = false)
      if checkRes.exitCode == 0 then
        val pids = checkRes.out.text().trim.split("\\s+").filter(_.nonEmpty)
        for pid <- pids do
          try os.proc("kill", pid).call(check = false) catch case _: Exception => ()
        return Right(())
    catch
      case _: Exception => ()

    println("\u001b[1;35m[polyomino whichkey]\u001b[0m Displaying Sway keybindings cheatsheet...")
    val keybindingsList = resolveSwayKeybindings(ctx)
    val entries = if keybindingsList.nonEmpty then keybindingsList else defaultKeybindings
    val inputList = entries.map(escapeMarkup).mkString("\n")

    val wofiConfigFile = ctx.configDir / "wofi" / "config"
    val wofiStyleFile = ctx.configDir / "wofi" / "style.css"

    val whichkeyArgs = Seq("wofi")
      ++ (if os.exists(wofiConfigFile) then Seq("--conf", wofiConfigFile.toString) else Seq.empty)
      ++ Seq(
        "--show", "dmenu",
        "--prompt", "[⊞] which-key",
        "--width", "880",
        "--lines", "8",
        "--columns", "2",
        "--insensitive",
        "--cache-file", "/dev/null"
      ) ++ (if os.exists(wofiStyleFile) then Seq("--style", wofiStyleFile.toString) else Seq.empty)

    try
      val shellableWhichkey: Seq[os.Shellable] = whichkeyArgs.map(s => (s: os.Shellable))
      os.proc(shellableWhichkey*).spawn(stdin = inputList)
      Right(())
    catch
      case e: Exception => Left(CommandError(s"Wofi whichkey failed: ${e.getMessage}"))

  private def escapeMarkup(str: String): String =
    str
      .replace("&", "&amp;")
      .replace("<", "&lt;")
      .replace(">", "&gt;")

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

  def expandBindings(config: String): Seq[String] =
    var varDefs = Map.empty[String, String]
    var bindings = Vector.empty[String]
    var inSubmode = false
    val seenActions = scala.collection.mutable.Set[String]()

    for rawLine <- config.linesIterator do
      // Strip comments from end of line
      val line = rawLine.takeWhile(_ != '#').trim
      if line.startsWith("mode ") && line.endsWith("{") then
        inSubmode = true
      else if inSubmode && line == "}" then
        inSubmode = false
      else if !inSubmode && line.nonEmpty then
        if line.startsWith("set ") then
          val parts = line.split("\\s+", 3)
          if parts.length >= 3 && parts(1).startsWith("$") then
            varDefs += (parts(1) -> parts(2).replace("\"", ""))
        else if line.startsWith("bindsym ") || line.startsWith("bindcode ") then
          var bindingLine = line
          bindingLine = bindingLine.replaceFirst("^(bindsym|bindcode)\\s+", "")
          while bindingLine.startsWith("--") do
            bindingLine = bindingLine.replaceFirst("^--[a-z-]+\\s+", "")

          for (varName, varVal) <- varDefs do
            bindingLine = bindingLine.replace(varName, varVal)

          val parts = bindingLine.split("\\s+", 2)
          if parts.length == 2 then
            val key = parts(0).trim
            val action = parts(1).trim
            
            // Skip raw numerical fallback keycodes (e.g. "107", "Mod4+61", "Mod4+193")
            val isRawCodeOnly = key.matches("^\\d+$") || key.matches("^.*\\+\\d+$")

            if !isRawCodeOnly then
              // Deduplicate whichkey and screenshot internal aliases
              val isWhichKey = action.contains("polyomino-whichkey")
              val isScreenshotFull = action.contains("polyomino screenshot full") || action.contains("polyomino-screenshot full")

              val shouldAdd = if isWhichKey then
                if seenActions.contains("whichkey") then false else { seenActions += "whichkey"; true }
              else if isScreenshotFull then
                if seenActions.contains("screenshot_full") then false else { seenActions += "screenshot_full"; true }
              else
                true

              if shouldAdd then
                val displayKey = if isWhichKey then "Mod4+? / Mod4+/" else key
                val displayAction = friendlyAction(action)
                bindings = bindings :+ f"$displayKey%-24s → $displayAction"

    bindings

  private def friendlyAction(action: String): String =
    action match
      case a if a.contains("polyomino-whichkey") => "Keybindings cheatsheet"
      case a if a.contains("polyomino-theme-picker") => "Theme and wallpaper picker"
      case a if a.contains("polyomino-lock") => "Lock screen (swaylock)"
      case a if a.contains("systemctl suspend") => "Suspend system"
      case a if a.contains("systemctl poweroff") => "Shutdown system"
      case a if a.contains("systemctl reboot") => "Reboot system"
      case a if a.contains("polyomino screenshot full") => "Screenshot full screen"
      case a if a.contains("polyomino screenshot region") => "Screenshot region selection"
      case a if a.contains("polyomino screenshot window") => "Screenshot active window"
      case a if a.contains("swaync-client -t -sw") => "Toggle notification center"
      case a if a.contains("kitty -e yazi") => "File manager (yazi)"
      case a if a.contains("kitty -e spotify_player") => "Spotify player TUI"
      case a if a.contains("kitty -e bluetui") => "Bluetooth manager (bluetui)"
      case a if a.contains("kitty -e impala") => "Network manager (impala)"
      case a if a.contains("kitty -e ncpamixer") => "Audio mixer (ncpamixer)"
      case a if a.contains("kitty -e aerc") => "Email client (aerc)"
      case a if a.contains("google-chrome-stable") => "Google Chrome"
      case a if a.contains("wdisplays") => "Display configuration (wdisplays)"
      case a if a.contains("swaynag") => "Exit Sway dialog"
      case a if a.contains("wofi --show drun") => "Application launcher"
      case a if a == "exec kitty" => "Open Kitty terminal"
      case a if a == "kill" => "Close focused window"
      case a if a == "reload" => "Reload Sway config"
      case a if a == "fullscreen" => "Toggle fullscreen"
      case a if a == "floating toggle" => "Toggle floating mode"
      case a if a == "focus mode_toggle" => "Toggle focus tiling/floating"
      case a if a == "focus parent" => "Focus parent container"
      case a if a == "splith" => "Split horizontal"
      case a if a == "splitv" => "Split vertical"
      case a if a == "layout toggle split" => "Toggle split layout"
      case a if a == "layout stacking" => "Layout stacking"
      case a if a == "layout tabbed" => "Layout tabbed"
      case a if a.startsWith("workspace number ") => s"Switch to Workspace ${a.stripPrefix("workspace number ")}"
      case a if a.startsWith("move container to workspace number ") => s"Move container to Workspace ${a.stripPrefix("move container to workspace number ")}"
      case a if a.startsWith("focus ") => s"Focus ${a.stripPrefix("focus ")}"
      case a if a.startsWith("move ") => s"Move ${a.stripPrefix("move ")}"
      case a if a == "move scratchpad" => "Move window to scratchpad"
      case a if a == "scratchpad show" => "Show scratchpad"
      case a if a == "mode \"resize\"" => "Enter resize mode"
      case other => other

  val defaultKeybindings: Seq[String] = Seq(
    "Mod4+Return              → Open Kitty terminal",
    "Mod4+d                   → Application launcher",
    "Mod4+Shift+q             → Close focused window",
    "Mod4+Shift+e             → Exit Sway dialog",
    "Mod4+f                   → Toggle fullscreen",
    "Mod4+v                   → Split vertical",
    "Mod4+b                   → Split horizontal",
    "Mod4+Shift+f             → File manager (yazi)",
    "Mod4+Shift+m             → Spotify (spotify_player)",
    "Mod4+Shift+u             → Bluetooth manager (bluetui)",
    "Mod4+Shift+v             → Audio mixer (ncpamixer)",
    "Mod4+Shift+a             → Email client (aerc)",
    "Mod4+Shift+n             → Toggle notification center",
    "Mod4+Shift+t             → Theme and wallpaper picker",
    "Mod4+? / Mod4+/          → Keybindings cheatsheet",
    "Mod4+Escape              → Lock screen (swaylock)",
    "Print                    → Screenshot full screen",
    "Mod4+Print               → Screenshot region selection",
    "Mod4+Shift+Print         → Screenshot active window"
  )
