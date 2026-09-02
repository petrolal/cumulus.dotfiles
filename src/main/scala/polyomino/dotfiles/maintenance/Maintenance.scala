package polyomino.dotfiles.maintenance

import polyomino.dotfiles.context.Context
import polyomino.dotfiles.error.{CommandError, PolyominoError}

object Maintenance:
  def runBackup(ctx: Context, args: List[String]): Either[PolyominoError, Unit] =
    val backupDir = ctx.home / ".local" / "share" / "polyomino" / "backups"
    os.makeDir.all(backupDir)
    val timestamp = System.currentTimeMillis()
    val archivePath = backupDir / s"polyomino-backup-$timestamp.tar.gz"

    println(s"\u001b[1;36m[polyomino backup]\u001b[0m Creating configuration snapshot at $archivePath...")
    try
      val configSway = ctx.configDir / "sway"
      if os.exists(configSway) then
        os.proc("tar", "-czf", archivePath.toString, "-C", ctx.configDir.toString, "sway").call(check = false)
        println(s"  \u001b[32m[OK]\u001b[0m Backup snapshot saved successfully (${os.size(archivePath)} bytes)")
        Right(())
      else
        Left(CommandError(s"Sway configuration path missing at $configSway", 1))
    catch
      case e: Exception => Left(CommandError(s"Backup failed: ${e.getMessage}"))

  def runRestore(ctx: Context, args: List[String]): Either[PolyominoError, Unit] =
    args.headOption match
      case None =>
        Left(CommandError("Usage: polyomino restore <path-to-archive.tar.gz>", 1))
      case Some(archiveStr) =>
        val archivePath = os.Path(archiveStr, os.pwd)
        println(s"\u001b[1;36m[polyomino restore]\u001b[0m Restoring configuration snapshot from $archivePath...")
        if os.exists(archivePath) then
          try
            os.proc("tar", "-xzf", archivePath.toString, "-C", ctx.configDir.toString).call(check = false)
            println(s"  \u001b[32m[OK]\u001b[0m Configuration restored to ${ctx.configDir}")
            Right(())
          catch
            case e: Exception => Left(CommandError(s"Restore failed: ${e.getMessage}"))
        else
          Left(CommandError(s"Backup archive missing at $archivePath", 1))

  def runUpdate(ctx: Context, args: List[String]): Either[PolyominoError, Unit] =
    println(s"\u001b[1;36m[polyomino update]\u001b[0m Pulling latest dotfiles updates in ${ctx.dotfilesDir}...")
    if os.exists(ctx.dotfilesDir) then
      try
        val res = os.proc("git", "pull", "--rebase").call(cwd = ctx.dotfilesDir, check = false)
        if res.exitCode == 0 then
          println("  \u001b[32m[OK]\u001b[0m Git pull complete. Triggering installer redeployment...")
          polyomino.dotfiles.install.DeployInstaller.run(ctx, args)
        else
          Left(CommandError(s"git pull failed with exit code ${res.exitCode}", res.exitCode))
      catch
        case e: Exception => Left(CommandError(s"Update failed: ${e.getMessage}"))
    else
      Left(CommandError(s"Dotfiles directory missing at ${ctx.dotfilesDir}", 1))
