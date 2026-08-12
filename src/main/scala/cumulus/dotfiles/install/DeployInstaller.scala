package cumulus.dotfiles.install

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}
import upickle.default._

object DeployInstaller:
  val Subcommands: Seq[String] = Seq(
    "theme", "runtime-refresh", "os-colorscheme", "rgb-theme", "lock", "idle",
    "screenshot", "autotiling", "validate", "backup", "restore", "update",
    "sdd", "install", "deploy", "install-fonts", "install-apps", "install-browser",
    "install-devops", "install-zsh", "install-sdkman", "install-nvim",
    "install-nvim-deps", "theme-picker", "whichkey", "wichkey"
  )

  def run(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    println("\u001b[1;32m[cumulus install]\u001b[0m Deploying cumulus.dotfiles configurations & symlinks...")
    val binDir = ctx.home / ".local" / "bin"
    os.makeDir.all(binDir)

    val mainBinary = binDir / "cumulus"
    println(s"  \u001b[32m[OK]\u001b[0m Target executable: $mainBinary")

    // Purge obsolete cumulus-* symlinks not in Subcommands
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
      println(s"  \u001b[32m[OK]\u001b[0m Cleaned up $purgedCount obsolete symlinks in $binDir")

    var manifestEntries = List.empty[ManifestEntry]

    // Preserve existing sway config
    val swayConfigDir = ctx.configDir / "sway"
    val swayBackupDir = ctx.configDir / "sway.bak"
    var backupPathOpt: Option[String] = None

    if os.exists(swayConfigDir) && !os.isLink(swayConfigDir) then
      try
        if os.exists(swayBackupDir) then os.remove.all(swayBackupDir)
        os.copy(swayConfigDir, swayBackupDir)
        backupPathOpt = Some(swayBackupDir.toString)
        println(s"  \u001b[32m[OK]\u001b[0m Preserved pre-existing config -> $swayBackupDir")
      catch
        case e: Exception => println(s"  \u001b[33m[NOTE]\u001b[0m Config backup skipped: ${e.getMessage}")

    var symlinkCount = 0
    for cmd <- Subcommands do
      val symlinkPath = binDir / s"cumulus-$cmd"
      try
        if os.exists(symlinkPath) || os.isLink(symlinkPath) then os.remove(symlinkPath)
        os.symlink(symlinkPath, mainBinary)
        symlinkCount += 1
        manifestEntries = manifestEntries :+ ManifestEntry(
          sourcePath = mainBinary.toString,
          targetPath = symlinkPath.toString,
          backupPath = None
        )
      catch
        case _: Exception => ()

    // Save manifest JSON
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
      println(s"  \u001b[32m[OK]\u001b[0m Manifest written -> $manifestFile (${manifestEntries.size} entries)")
    catch
      case e: Exception => println(s"  \u001b[33m[NOTE]\u001b[0m Manifest write failed: ${e.getMessage}")

    println(s"  \u001b[32m[OK]\u001b[0m Created $symlinkCount subcommand symlinks in $binDir")
    println("\n\u001b[1;32m[SUCCESS]\u001b[0m cumulus.dotfiles deployment complete!")
    Right(())
