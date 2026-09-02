package polyomino.dotfiles.context

import polyomino.dotfiles.error.{ConfigError, PolyominoError}
import os.Path

case class Context(
    home: Path,
    configDir: Path,
    shareDir: Path,
    dotfilesDir: Path,
    swaySocket: Option[String]
)

object Context:
  def discover(): Either[PolyominoError, Context] =
    try
      val home = os.home
      val configDir = sys.env.get("XDG_CONFIG_HOME").map(os.Path(_)).getOrElse(home / ".config")
      val shareDir = sys.env.get("XDG_DATA_HOME").map(os.Path(_)).getOrElse(home / ".local" / "share" / "polyomino")
      val dotfilesDir = sys.env.get("CUMULUS_DOTFILES_DIR").map(os.Path(_)).getOrElse(home / "polyomino.dotfiles")
      val swaySocket = sys.env.get("SWAYSOCK")

      Right(Context(
        home = home,
        configDir = configDir,
        shareDir = shareDir,
        dotfilesDir = dotfilesDir,
        swaySocket = swaySocket
      ))
    catch
      case e: Exception => Left(ConfigError(e.getMessage))
