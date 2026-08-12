package cumulus.dotfiles.theme

import upickle.default._

case class Palette(
    name: String,
    base: String,
    mantle: String,
    text: String,
    accent: String,
    red: String,
    green: String,
    yellow: String,
    blue: String
) derives ReadWriter

object Palette:
  val CatppuccinMocha: Palette = Palette(
    name = "catppuccin-mocha",
    base = "#1e1e2e",
    mantle = "#181825",
    text = "#cdd6f4",
    accent = "#89b4fa",
    red = "#f38ba8",
    green = "#a6e3a1",
    yellow = "#f9e2af",
    blue = "#89b4fa"
  )

  val Nord: Palette = Palette(
    name = "nord",
    base = "#2e3440",
    mantle = "#2b303c",
    text = "#eceff4",
    accent = "#88c0d0",
    red = "#bf616a",
    green = "#a3be8c",
    yellow = "#ebcb8b",
    blue = "#81a1c1"
  )

  val TokyoNight: Palette = Palette(
    name = "tokyonight",
    base = "#1a1b26",
    mantle = "#16161e",
    text = "#a9b1d6",
    accent = "#7aa2f7",
    red = "#f7768e",
    green = "#9ece6a",
    yellow = "#e0af68",
    blue = "#7aa2f7"
  )

  def find(name: String): Palette =
    name.toLowerCase match
      case "nord" => Nord
      case "tokyonight" => TokyoNight
      case _ => CatppuccinMocha
