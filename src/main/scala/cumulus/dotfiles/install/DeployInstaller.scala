package cumulus.dotfiles.install

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}

object DeployInstaller:
  val Subcommands: Seq[String] = Seq(
    "theme", "runtime-refresh", "os-colorscheme", "rgb-theme", "lock", "idle",
    "screenshot", "autotiling", "validate", "backup", "restore", "update",
    "sdd", "install", "deploy", "install-fonts", "install-apps", "install-browser",
    "install-devops", "install-zsh", "install-sdkman", "install-nvim",
    "install-nvim-deps", "theme-picker", "whichkey"
  )

  def run(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    println("\u001b[1;32m[cumulus install]\u001b[0m Deploying cumulus.dotfiles configurations & symlinks...")
    val binDir = ctx.home / ".local" / "bin"
    os.makeDir.all(binDir)

    val mainBinary = binDir / "cumulus"
    println(s"  \u001b[32m[OK]\u001b[0m Target executable: $mainBinary")

    var symlinkCount = 0
    for cmd <- Subcommands do
      val symlinkPath = binDir / s"cumulus-$cmd"
      try
        if os.exists(symlinkPath) || os.isDir(symlinkPath) then os.remove(symlinkPath)
        os.symlink(symlinkPath, mainBinary)
        symlinkCount += 1
      catch
        case _: Exception => ()

    println(s"  \u001b[32m[OK]\u001b[0m Created $symlinkCount subcommand symlinks in $binDir")
    println("\n\u001b[1;32m[SUCCESS]\u001b[0m cumulus.dotfiles deployment complete!")
    Right(())
