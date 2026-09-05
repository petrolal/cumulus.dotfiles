package polyomino.dotfiles.theme

import polyomino.dotfiles.context.Context
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
  val FallbackPalette: Palette = Palette(
    name = "matriz",
    label = "Matriz (Gold/Teal)",
    base = "#0F1117",
    mantle = "#191C24",
    text = "#F8FAFC",
    accent = "#EBB434",
    red = "#EF4444",
    green = "#10B981",
    yellow = "#F59E0B",
    blue = "#EBB434"
  )

  def listAll(ctx: Context): Seq[String] = {
    val discovered = discoverConfFiles(ctx).keys.toSeq
    val core = Seq("matriz", "encruza", "caravela", "aruanda")
    (discovered ++ core).distinct.sorted
  }

  def find(name: String, ctx: Context): Palette = {
    val lower = name.toLowerCase
    val confMap = discoverConfFiles(ctx)
    confMap.get(lower).getOrElse(FallbackPalette)
  }

  private def discoverConfFiles(ctx: Context): Map[String, Palette] =
    var result = Map.empty[String, Palette]
    val searchDirs = Seq(
      ctx.dotfilesDir / "themes" / "palettes",
      ctx.configDir / "polyomino" / "themes"
    )

    for dir <- searchDirs if os.exists(dir) do
      for file <- os.list(dir) if file.ext == "conf" do
        parseConfFile(file).foreach { pal =>
          result += (pal.name.toLowerCase -> pal)
          result += (file.baseName.toLowerCase -> pal)
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
          // Extract value between the first and last double quotes, ignore comments and stray characters
          val raw = parts(1).trim
          val firstQuote = raw.indexOf("\"")
          val lastQuote = raw.lastIndexOf("\"")
          val extracted = if (firstQuote >= 0 && lastQuote > firstQuote) {
            raw.substring(firstQuote + 1, lastQuote)
          } else {
            raw.split("#", 2)(0).trim // fallback to raw before comment
          }
          val v = extracted.stripSuffix("\\") // remove trailing backslash if present
          kvMap += (k -> v)

      val name = kvMap.getOrElse("THEME_NAME", file.baseName)
      val label = kvMap.getOrElse("THEME_LABEL", name)
      val base = kvMap.getOrElse("BASE", "#0F1117")
      val mantle = kvMap.getOrElse("MANTLE", base)
      val text = kvMap.getOrElse("TEXT", "#F8FAFC")
      val accent = kvMap.getOrElse("BLUE", kvMap.getOrElse("ACCENT", "#EBB434"))
      val red = kvMap.getOrElse("RED", "#EF4444")
      val green = kvMap.getOrElse("GREEN", "#10B981")
      val yellow = kvMap.getOrElse("YELLOW", "#F59E0B")
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
