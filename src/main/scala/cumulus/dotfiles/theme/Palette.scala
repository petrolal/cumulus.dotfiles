package cumulus.dotfiles.theme

import cumulus.dotfiles.context.Context
import upickle.default._

case class Palette(
    name: String,
    label: String,
    base: String,
    mantle: String,
    text: String,
    accent: String,
    red: String,
    green: String,
    yellow: String,
    blue: String,
    wallpaper: Option[String] = None
) derives ReadWriter

object Palette:
  val BuiltinPalettes: Map[String, Palette] = Map(
    "catppuccin-mocha" -> Palette(
      name = "catppuccin-mocha",
      label = "Catppuccin Mocha (Dark)",
      base = "#1e1e2e",
      mantle = "#181825",
      text = "#cdd6f4",
      accent = "#89b4fa",
      red = "#f38ba8",
      green = "#a6e3a1",
      yellow = "#f9e2af",
      blue = "#89b4fa"
    ),
    "catppuccin-latte" -> Palette(
      name = "catppuccin-latte",
      label = "Catppuccin Latte (Light)",
      base = "#eff1f5",
      mantle = "#e6e9ef",
      text = "#4c4f69",
      accent = "#1e66f5",
      red = "#d20f39",
      green = "#40a02b",
      yellow = "#df8e1d",
      blue = "#1e66f5"
    ),
    "nord" -> Palette(
      name = "nord",
      label = "Nord Frost (Dark)",
      base = "#2e3440",
      mantle = "#2b303c",
      text = "#eceff4",
      accent = "#88c0d0",
      red = "#bf616a",
      green = "#a3be8c",
      yellow = "#ebcb8b",
      blue = "#81a1c1"
    ),
    "tokyonight" -> Palette(
      name = "tokyonight",
      label = "Tokyo Night (Dark)",
      base = "#1a1b26",
      mantle = "#16161e",
      text = "#a9b1d6",
      accent = "#7aa2f7",
      red = "#f7768e",
      green = "#9ece6a",
      yellow = "#e0af68",
      blue = "#7aa2f7"
    ),
    "gruvbox-dark" -> Palette(
      name = "gruvbox-dark",
      label = "Gruvbox Dark",
      base = "#282828",
      mantle = "#1d2021",
      text = "#ebdbb2",
      accent = "#fe8019",
      red = "#fb4934",
      green = "#b8bb26",
      yellow = "#fabd2f",
      blue = "#83a598"
    ),
    "dracula" -> Palette(
      name = "dracula",
      label = "Dracula Dark",
      base = "#282a36",
      mantle = "#21222c",
      text = "#f8f8f2",
      accent = "#bd93f9",
      red = "#ff5555",
      green = "#50fa7b",
      yellow = "#f1fa8c",
      blue = "#8be9fd"
    ),
    "rose-pine" -> Palette(
      name = "rose-pine",
      label = "Rosé Pine Dark",
      base = "#191724",
      mantle = "#1f1d2e",
      text = "#e0def4",
      accent = "#ebbcba",
      red = "#eb6f92",
      green = "#9ccfd8",
      yellow = "#f6c177",
      blue = "#31748f"
    )
  )

  def listAll(ctx: Context): Seq[String] =
    val discovered = discoverConfFiles(ctx).keys.toSeq
    val allNames = (BuiltinPalettes.keys.toSeq ++ discovered).distinct.sorted
    allNames

  def find(name: String, ctx: Context): Palette =
    val lower = name.toLowerCase
    val confMap = discoverConfFiles(ctx)
    if confMap.contains(lower) then
      confMap(lower)
    else if BuiltinPalettes.contains(lower) then
      BuiltinPalettes(lower)
    else
      BuiltinPalettes("catppuccin-mocha")

  private def discoverConfFiles(ctx: Context): Map[String, Palette] =
    var result = Map.empty[String, Palette]
    val searchDirs = Seq(
      ctx.dotfilesDir / "themes" / "palettes",
      ctx.configDir / "cumulus" / "themes"
    )

    for dir <- searchDirs if os.exists(dir) do
      for file <- os.list(dir) if file.ext == "conf" do
        parseConfFile(file).foreach { pal =>
          result += (pal.name.toLowerCase -> pal)
        }

    result

  private def parseConfFile(file: os.Path): Option[Palette] =
    try
      val lines = os.read.lines(file)
      var kvMap = Map.empty[String, String]
      for line <- lines do
        val trimmed = line.trim
        if !trimmed.startsWith("#") && trimmed.contains("=") then
          val parts = trimmed.split("=", 2)
          val k = parts(0).trim.toUpperCase
          val v = parts(1).trim.stripPrefix("\"").stripSuffix("\"")
          kvMap += (k -> v)

      val name = kvMap.getOrElse("THEME_NAME", file.baseName)
      val label = kvMap.getOrElse("THEME_LABEL", name)
      val base = kvMap.getOrElse("BASE", "#1e1e2e")
      val mantle = kvMap.getOrElse("MANTLE", base)
      val text = kvMap.getOrElse("TEXT", "#cdd6f4")
      val accent = kvMap.getOrElse("BLUE", kvMap.getOrElse("ACCENT", "#89b4fa"))
      val red = kvMap.getOrElse("RED", "#f38ba8")
      val green = kvMap.getOrElse("GREEN", "#a6e3a1")
      val yellow = kvMap.getOrElse("YELLOW", "#f9e2af")
      val blue = kvMap.getOrElse("BLUE", accent)

      Some(Palette(
        name = name,
        label = label,
        base = base,
        mantle = mantle,
        text = text,
        accent = accent,
        red = red,
        green = green,
        yellow = yellow,
        blue = blue
      ))
    catch
      case _: Exception => None
