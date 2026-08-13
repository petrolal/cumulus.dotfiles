package cumulus.dotfiles.install

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}
import upickle.default._

object DeployInstaller:
  val Subcommands: Seq[String] = Seq(
    "theme", "runtime-refresh", "os-colorscheme", "lock", "idle",
    "screenshot", "autotiling", "healthcheck", "backup", "restore", "update",
    "sdd", "install", "deploy", "install-deps", "install-fonts", "install-apps", "install-browser",
    "install-devops", "install-zsh", "install-sdkman", "install-nvim",
    "install-nvim-deps", "install-all", "theme-picker", "whichkey", "wichkey"
  )

  def run(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    println("[1;32m[cumulus install][0m Deploying cumulus.dotfiles configurations & symlinks...")
    val binDir = ctx.home / ".local" / "bin"
    os.makeDir.all(binDir)

    val mainBinary = binDir / "cumulus"
    println(s"  [32m[OK][0m Target executable: $mainBinary")

    var manifestEntries = List.empty[ManifestEntry]

    // 1. Clean & deploy dotfile configuration symlinks from scratch
    val timestamp = System.currentTimeMillis()
    val backupBaseDir = ctx.home / ".cumulus_backup" / timestamp.toString

    val configMappings = Seq(
      (ctx.home / ".zshrc", ctx.dotfilesDir / "zsh" / ".zshrc"),
      (ctx.configDir / "cumulus" / "zsh_config", ctx.dotfilesDir / "zsh" / "zsh_config"),
      (ctx.configDir / "sway", ctx.dotfilesDir / "config" / "sway"),
      (ctx.configDir / "kitty", ctx.dotfilesDir / "config" / "kitty"),
      (ctx.configDir / "waybar", ctx.dotfilesDir / "config" / "waybar"),
      (ctx.configDir / "wofi", ctx.dotfilesDir / "config" / "wofi"),
      (ctx.configDir / "rofi", ctx.dotfilesDir / "config" / "rofi"),
      (ctx.configDir / "mako", ctx.dotfilesDir / "config" / "mako")
    )

    var configSymlinkCount = 0
    for (targetPath, sourcePath) <- configMappings do
      if os.exists(sourcePath) then
        var backupPathOpt: Option[String] = None

        if os.exists(targetPath) && !os.isLink(targetPath) then
          try
            val backupTarget = backupBaseDir / targetPath.last
            os.makeDir.all(backupBaseDir)
            os.copy(targetPath, backupTarget)
            backupPathOpt = Some(backupTarget.toString)
            println(s"  [32m[OK][0m Preserved pre-existing config -> $backupTarget")
          catch
            case e: Exception => println(s"  [33m[NOTE][0m Config backup skipped for ${targetPath.last}: ${e.getMessage}")

        // Remove any existing path (file or directory) to make room for symlink
        try
          if os.exists(targetPath) then os.remove.all(targetPath)
          if os.isLink(targetPath) then os.remove(targetPath)
        catch
          case e: Exception => println(s"  [33m[WARN][0m Could not remove existing $targetPath: ${e.getMessage}")

        // Create symlink if path was successfully removed
        if !os.exists(targetPath) && !os.isLink(targetPath) then
          try
            val parentStr = targetPath.toString
            val parentPath = os.Path(parentStr.substring(0, parentStr.lastIndexOf('/')))
            os.makeDir.all(parentPath)
            // Use ln command for more reliable symlink creation
            os.proc("ln", "-s", sourcePath.toString, targetPath.toString).call()
            configSymlinkCount += 1
            manifestEntries = manifestEntries :+ ManifestEntry(
              sourcePath = sourcePath.toString,
              targetPath = targetPath.toString,
              backupPath = backupPathOpt
            )
            println(s"  [32m[OK][0m Symlinked $targetPath -> $sourcePath")
          catch
            case e: Exception => println(s"  [33m[NOTE][0m Symlink creation failed for ${targetPath.last}: ${e.getMessage}")
        else
          println(s"  [33m[WARN][0m Skipping symlink for ${targetPath.last} - could not remove existing path")

    // 2. Purge obsolete cumulus-* symlinks not in Subcommands
    val validSymlinkNames = Subcommands.map(cmd => s"cumulus-$cmd").toSet
    var purgedCount = 0
    if os.exists(binDir) then
      for file <- os.list(binDir) do
        val filename = file.last
        if filename.startsWith("cumulus-") && !validSymlinkNames.contains(filename) then
          try
            os.remove(file)
            purgedCount += 1
          catch case _: Exception => ()

    if purgedCount > 0 then
      println(s"  [32m[OK][0m Cleaned up $purgedCount obsolete symlinks in $binDir")

    // 3. Clean & deploy CLI subcommand symlinks in ~/.local/bin/
    var binSymlinkCount = 0
    for cmd <- Subcommands do
      val symlinkPath = binDir / s"cumulus-$cmd"
      try
        if os.exists(symlinkPath) || os.isLink(symlinkPath) then os.remove(symlinkPath)
        // Use ln command for reliable symlink creation
        os.proc("ln", "-s", mainBinary.toString, symlinkPath.toString).call()
        binSymlinkCount += 1
        manifestEntries = manifestEntries :+ ManifestEntry(
          sourcePath = mainBinary.toString,
          targetPath = symlinkPath.toString,
          backupPath = None
        )
      catch
        case e: Exception => println(s"  [33m[NOTE][0m Failed to create symlink for cumulus-$cmd: ${e.getMessage}")

    // 4. Save manifest JSON
    val manifestDir = ctx.shareDir
    os.makeDir.all(manifestDir)
    val manifestFile = manifestDir / "manifest.json"
    val manifestData = Manifest(
      version = "0.1.0",
      timestamp = System.currentTimeMillis(),
      entries = manifestEntries
    )

    try
      val jsonText = write(manifestData, indent = 2)
      os.write.over(manifestFile, jsonText)
      println(s"  [32m[OK][0m Manifest written -> $manifestFile (${manifestEntries.size} entries)")
    catch
      case e: Exception => println(s"  [33m[NOTE][0m Manifest write failed: ${e.getMessage}")

    println(s"  [32m[OK][0m Created $configSymlinkCount config symlinks and $binSymlinkCount CLI subcommand symlinks")
    println("\n[1;32m[SUCCESS][0m cumulus.dotfiles deployment complete!")

    // Apply active desktop theme to re-render all config files
    val activePalette = cumulus.dotfiles.theme.ThemeEngine.getActivePalette(ctx)
    cumulus.dotfiles.theme.ThemeEngine.applyTheme(ctx, activePalette.name)

    if !args.contains("--links-only") then
      println("\n[1;32m[cumulus install-all][0m Installing all system dependencies, desktop apps, fonts, and tooling...")
      for
        _ <- ToolInstallers.runTool("install-all", ctx, args)
        _ <- cumulus.dotfiles.validate.Validator.run(ctx, args)
      yield ()
    else
      Right(())
