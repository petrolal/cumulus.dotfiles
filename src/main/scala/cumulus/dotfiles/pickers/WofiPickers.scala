package cumulus.dotfiles.pickers

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}

object WofiPickers:
  def runThemePicker(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    println("\u001b[1;35m[cumulus theme-picker]\u001b[0m Launching Wofi GUI theme picker...")
    val themes = Seq(
      "catppuccin-mocha",
      "catppuccin-latte",
      "nord",
      "tokyonight",
      "gruvbox-dark",
      "dracula",
      "rose-pine"
    )
    val inputList = themes.mkString("\n")

    try
      val res = os.proc(
        "wofi", "--show", "dmenu",
        "--prompt", "Select Theme",
        "--width", "400",
        "--lines", "10",
        "--cache-file", "/dev/null"
      ).call(stdin = inputList, check = false)
      
      val selected = res.out.text().trim
      if selected.nonEmpty then
        println(s"  \u001b[32m[OK]\u001b[0m Selected theme '$selected'")
        cumulus.dotfiles.theme.ThemeEngine.run(ctx, List(selected))
      else
        Right(())
    catch
      case e: Exception => Left(CommandError(s"Wofi theme-picker failed: ${e.getMessage}"))

  def runWhichkey(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    println("\u001b[1;35m[cumulus whichkey]\u001b[0m Displaying Sway keybindings cheatsheet...")
    val keybindingsList = resolveSwayKeybindings(ctx)
    val inputList = if keybindingsList.nonEmpty then keybindingsList.mkString("\n") else defaultKeybindings.mkString("\n")

    try
      os.proc(
        "wofi", "--show", "dmenu",
        "--prompt", "which-key",
        "--width", "700",
        "--lines", "20",
        "--cache-file", "/dev/null"
      ).call(stdin = inputList, check = false)
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
      case _: Exception => ""

  private def expandBindings(config: String): Seq[String] =
    var varDefs = Map.empty[String, String]
    var bindings = Vector.empty[String]

    for line <- config.linesIterator do
      val trimmed = line.trim
      if trimmed.startsWith("set ") then
        val parts = trimmed.split("\\s+", 3)
        if parts.length >= 3 && parts(1).startsWith("$") then
          varDefs += (parts(1) -> parts(2).replace("\"", ""))
      else if trimmed.startsWith("bindsym ") || trimmed.startsWith("bindcode ") then
        var bindingLine = trimmed.stripPrefix("bindsym ").stripPrefix("bindcode ").trim
        for (varName, varVal) <- varDefs do
          bindingLine = bindingLine.replace(varName, varVal)
        val parts = bindingLine.split("\\s+", 2)
        if parts.length == 2 then
          val key = parts(0)
          val action = parts(1)
          bindings = bindings :+ f"$key%-22s → $action"
        else
          bindings = bindings :+ bindingLine

    bindings

  private val defaultKeybindings = Seq(
    "Mod+Return            → Open Kitty Terminal",
    "Mod+D                 → Open Wofi Launcher",
    "Mod+Shift+Q           → Close Focused Window",
    "Mod+Shift+E           → Exit Sway",
    "Mod+F                 → Toggle Fullscreen",
    "Mod+V                 → Toggle Split Layout",
    "Mod+Shift+L           → Lock Screen (cumulus-lock)",
    "Mod+Shift+P           → Theme Picker (cumulus-theme-picker)",
    "Mod+Shift+S           → Screenshot Region (cumulus-screenshot)"
  )
