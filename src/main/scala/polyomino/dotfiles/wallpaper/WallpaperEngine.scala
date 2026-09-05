package polyomino.dotfiles.wallpaper

import polyomino.dotfiles.context.Context
import polyomino.dotfiles.error.{CommandError, PolyominoError}
import polyomino.dotfiles.theme.ThemeEngine

/** Wallpaper selection scoped to the *active* theme flavor.
  *
  * `polyomino theme <flavor>` owns the palette + the initial wallpaper; this module
  * lets you swap between the multiple wallpapers that ship for the current flavor
  * (`themes/wallpapers/<flavor>.svg`, `<flavor>_2.svg`, `<flavor>-nebula.svg`, …)
  * without re-rendering every app surface.
  */
object WallpaperEngine:
  private val ImageExts = Set("svg", "png", "jpg", "jpeg", "webp")

  def run(ctx: Context, args: List[String]): Either[PolyominoError, Unit] =
    args match
      case Nil =>
        polyomino.dotfiles.pickers.WofiPickers.runWallpaperPicker(ctx, Nil)
      case ("next" | "cycle") :: _        => cycle(ctx, +1)
      case ("prev" | "previous") :: _     => cycle(ctx, -1)
      case "random" :: _                  => random(ctx)
      case ("list" | "--list") :: _       => listCmd(ctx)
      case ("current" | "--current") :: _ =>
        currentWallpaper(ctx) match
          case Some(w) => Right(println(w))
          case None    => Right(println("(none)"))
      case target :: _ => setByName(ctx, target)

  /** Flavor of the currently applied theme (falls back to `matriz`). */
  def activeFlavor(ctx: Context): String =
    ThemeEngine.getActivePalette(ctx).name

  /** All wallpapers that belong to `flavor`, sorted by filename.
    *
    * A file belongs to a flavor when its basename is exactly `<flavor>` or starts
    * with `<flavor>` followed by a separator (`-`, `_`, `.`), so `matriz.svg`,
    * `matriz_2.png` and `matriz-aurora.svg` all match `matriz` but `matrixx.svg`
    * and `caravela.svg` do not.
    */
  def wallpapersForFlavor(ctx: Context, flavor: String): Seq[os.Path] =
    val dir = ctx.dotfilesDir / "themes" / "wallpapers"
    if !os.exists(dir) then Seq.empty
    else
      val f = flavor.toLowerCase
      os.list(dir)
        .filter(p => os.isFile(p) && ImageExts.contains(p.ext.toLowerCase))
        .filter { p =>
          val stem = p.baseName.toLowerCase
          stem == f || (stem.startsWith(f) && !stem.charAt(f.length).isLetterOrDigit)
        }
        .sortBy(_.last.toLowerCase)
        .toSeq

  def currentWallpaper(ctx: Context): Option[String] =
    val stateFile = ctx.configDir / "polyomino" / "theme" / "state"
    if !os.exists(stateFile) then None
    else
      os.read.lines(stateFile)
        .find(_.startsWith("WALLPAPER="))
        .map(_.stripPrefix("WALLPAPER=").trim)
        .filter(_.nonEmpty)

  /** Point the active theme at `wallpaper` (an absolute path), live + persisted. */
  def applyWallpaper(ctx: Context, wallpaper: os.Path): Either[PolyominoError, Unit] =
    if !os.exists(wallpaper) then
      Left(CommandError(s"wallpaper not found: $wallpaper"))
    else
      val path = wallpaper.toString
      println(s"[1;35m[polyomino wallpaper][0m ${wallpaper.last} (flavor: ${activeFlavor(ctx)})")

      updateStateWallpaper(ctx, path)
      rewriteLine(
        ctx.configDir / "sway" / "colors.conf",
        line => line.startsWith("output ") && line.contains(" bg ") || line.startsWith("# No wallpaper"),
        s"""output * bg "$path" fill"""
      )
      rewriteLine(
        ctx.configDir / "swaylock" / "config",
        line => line.startsWith("image=") || line.startsWith("color="),
        s"image=$path"
      )

      try
        os.proc("timeout", "2", "swaymsg", "output", "*", "bg", path, "fill")
          .call(check = false, stdout = os.Pipe, stderr = os.Pipe)
        println(s"  [32m[OK][0m Applied live via Sway")
      catch case _: Exception => ()

      Right(())

  private def cycle(ctx: Context, step: Int): Either[PolyominoError, Unit] =
    val flavor = activeFlavor(ctx)
    val options = wallpapersForFlavor(ctx, flavor)
    if options.isEmpty then
      Left(CommandError(s"no wallpapers found for flavor '$flavor' in themes/wallpapers/"))
    else
      val cur = currentWallpaper(ctx)
      val idx = cur.flatMap(c => options.indexWhere(_.toString == c) match
        case -1 => None
        case i  => Some(i)
      ).getOrElse(if step > 0 then -1 else 0)
      val nextIdx = ((idx + step) % options.size + options.size) % options.size
      applyWallpaper(ctx, options(nextIdx))

  private def random(ctx: Context): Either[PolyominoError, Unit] =
    val flavor = activeFlavor(ctx)
    val options = wallpapersForFlavor(ctx, flavor)
    if options.isEmpty then
      Left(CommandError(s"no wallpapers found for flavor '$flavor' in themes/wallpapers/"))
    else
      val cur = currentWallpaper(ctx)
      val pool = options.filterNot(p => cur.contains(p.toString))
      val pick = (if pool.nonEmpty then pool else options)(scala.util.Random.nextInt(if pool.nonEmpty then pool.size else options.size))
      applyWallpaper(ctx, pick)

  private def setByName(ctx: Context, target: String): Either[PolyominoError, Unit] =
    val direct = try Some(os.Path(target, os.pwd)) catch case _: Exception => None
    direct.filter(os.exists) match
      case Some(p) => applyWallpaper(ctx, p)
      case None =>
        val flavor = activeFlavor(ctx)
        val options = wallpapersForFlavor(ctx, flavor)
        options.find(p => p.last == target || p.baseName == target) match
          case Some(p) => applyWallpaper(ctx, p)
          case None =>
            Left(CommandError(
              s"'$target' is not a file and no wallpaper for flavor '$flavor' matches it. " +
              s"Try `polyomino wallpaper list`."
            ))

  private def listCmd(ctx: Context): Either[PolyominoError, Unit] =
    val flavor = activeFlavor(ctx)
    val options = wallpapersForFlavor(ctx, flavor)
    if options.isEmpty then
      println(s"No wallpapers for flavor '$flavor' in ${ctx.dotfilesDir / "themes" / "wallpapers"}")
    else
      val cur = currentWallpaper(ctx)
      println(s"Wallpapers for '$flavor':")
      for p <- options do
        val marker = if cur.contains(p.toString) then "[32m*[0m" else " "
        println(s"  $marker ${p.last}")
    Right(())

  private def updateStateWallpaper(ctx: Context, path: String): Unit =
    try
      val stateFile = ctx.configDir / "polyomino" / "theme" / "state"
      if os.exists(stateFile) then
        val updated = os.read.lines(stateFile).map { line =>
          if line.startsWith("WALLPAPER=") then s"WALLPAPER=$path"
          else if line.startsWith("WALLPAPER_SOURCE=") then "WALLPAPER_SOURCE=single"
          else if line.startsWith("MODE=") then "MODE=wallpaper"
          else line
        }
        val withWallpaper =
          if updated.exists(_.startsWith("WALLPAPER=")) then updated
          else updated :+ s"WALLPAPER=$path"
        os.write.over(stateFile, withWallpaper.mkString("\n") + "\n")
        println(s"  [32m[OK][0m State updated -> $stateFile")
    catch case _: Exception => ()

  /** Replace the first line matching `pred` with `replacement`; no-op if the file
    * is missing or nothing matches (theme engine will regenerate it next apply).
    */
  private def rewriteLine(file: os.Path, pred: String => Boolean, replacement: String): Unit =
    try
      if os.exists(file) then
        val lines = os.read.lines(file).toVector
        val i = lines.indexWhere(pred)
        if i >= 0 && lines(i) != replacement then
          os.write.over(file, lines.updated(i, replacement).mkString("\n") + "\n")
          println(s"  [32m[OK][0m Rewrote wallpaper line -> ${file.last}")
    catch case _: Exception => ()
