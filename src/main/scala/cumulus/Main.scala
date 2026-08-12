package cumulus

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CumulusError, UnknownCommandError}

object Main:
  def main(args: Array[String]): Unit =
    val exitCode = dispatch(args)
    if exitCode != 0 then sys.exit(exitCode)

  def dispatch(args: Array[String]): Int =
    val rawProg = sys.env.getOrElse("CUMULUS_PROG_NAME", getArgv0())
    val progName = if rawProg.nonEmpty then rawProg else "cumulus"
    val binaryBasename = try os.Path(progName, os.pwd).last catch case _: Exception => progName

    val (cmd, restArgs) = if binaryBasename.startsWith("cumulus-") then
      (binaryBasename.stripPrefix("cumulus-"), args.toList)
    else
      args.headOption match
        case Some(cmdArg) if !cmdArg.startsWith("-") => (cmdArg, args.tail.toList)
        case _ =>
          printUmbrellaHelp()
          return 0

    runCommand(cmd, restArgs) match
      case Right(_) => 0
      case Left(err) =>
        if err.message.nonEmpty then
          println(s"\u001b[1;31m[cumulus] error:\u001b[0m ${err.message}")
        err.code

  private def getArgv0(): String =
    try
      val bytes = java.nio.file.Files.readAllBytes(java.nio.file.Paths.get("/proc/self/cmdline"))
      val nul = bytes.indexOf(0.toByte)
      if nul > 0 then new String(bytes, 0, nul, "UTF-8")
      else new String(bytes, "UTF-8")
    catch
      case _: Exception => ""

  private def runCommand(name: String, args: List[String]): Either[CumulusError, Unit] =
    for
      ctx <- Context.discover()
      res <- dispatchModule(name, ctx, args)
    yield res

  private def dispatchModule(name: String, ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    name match
      case "version" | "-v" | "--version" => Right(println("cumulus 0.1.0 (Scala 3.5.2 Native Image)"))
      case "validate" => cumulus.dotfiles.validate.Validator.run(ctx, args)
      case "sdd" => cumulus.dotfiles.sdd.SpecDrivenDev.run(ctx, args)
      case "lock" => cumulus.dotfiles.sysutils.SysUtils.runLock(ctx)
      case "idle" => cumulus.dotfiles.sysutils.SysUtils.runIdle(ctx)
      case "screenshot" => cumulus.dotfiles.sysutils.SysUtils.runScreenshot(ctx, args)
      case "theme" => cumulus.dotfiles.theme.ThemeEngine.run(ctx, args)
      case "runtime-refresh" => cumulus.dotfiles.refresh.RefreshEngine.runRefresh(ctx)
      case "os-colorscheme" => cumulus.dotfiles.refresh.RefreshEngine.runOsColorscheme(ctx)
      case "autotiling" => cumulus.dotfiles.autotiling.AutotilingDaemon.run(ctx, args)
      case "theme-picker" => cumulus.dotfiles.pickers.WofiPickers.runThemePicker(ctx, args)
      case "whichkey" | "wichkey" => cumulus.dotfiles.pickers.WofiPickers.runWhichkey(ctx, args)
      case "backup" => cumulus.dotfiles.maintenance.Maintenance.runBackup(ctx, args)
      case "restore" => cumulus.dotfiles.maintenance.Maintenance.runRestore(ctx, args)
      case "update" => cumulus.dotfiles.maintenance.Maintenance.runUpdate(ctx, args)
      case "install" | "deploy" => cumulus.dotfiles.install.DeployInstaller.run(ctx, args)
      case name if name.startsWith("install-") => cumulus.dotfiles.install.ToolInstallers.runTool(name, ctx, args)
      case other => Left(UnknownCommandError(other))

  val UmbrellaHelp: String =
    """cumulus — tooling for the cumulus.dotfiles Sway/Wayland desktop.
      |
      |Usage:
      |  cumulus <command> [args...]
      |  cumulus-<command> [args...]      (installed alias)
      |
      |Commands:
      |  install          deploy cumulus.dotfiles onto a machine (full setup)
      |  theme            select a desktop flavor + background mode and apply it live
      |  runtime-refresh  refresh running apps (sway/waybar/kitty/wofi/neovim/os)
      |  os-colorscheme   sync the GNOME/GTK color-scheme setting
      |  lock             lock the screen (swaylock) styled to the active theme
      |  idle             run the swayidle daemon (auto-lock, dpms, suspend)
      |  screenshot       capture a screenshot (full|region|window)
      |  autotiling       Fibonacci spiral autotiling daemon for Sway
      |  validate         read-only health check of the deployed setup
      |  backup           snapshot managed configs to a timestamped tarball
      |  restore          restore a snapshot created by backup
      |  update           git pull the dotfiles and re-run the installer
      |  sdd              token-efficient spec-driven development for AI workflows
      |  install-deps     install system & build dependencies (sbt, gcc, git, etc.)
      |  install-fonts    install the JetBrainsMono Nerd Font
      |  install-apps     install core desktop apps (sway/waybar/kitty/etc.)
      |  install-browser  install a web browser (chromium/firefox)
      |  install-devops   install devops tooling (docker/terraform/kubectl/etc.)
      |  install-zsh      install zsh + oh-my-zsh + plugins and set the shell
      |  install-sdkman   install SDKMAN! and JVM tooling
      |  install-nvim     install the Neovim config dependencies (deploy)
      |  install-nvim-deps install Neovim + its plugin ecosystem dependencies
      |  install-all      install all system packages, desktop apps, fonts, and tooling
      |  theme-picker     wofi GUI front-end for the theme command
      |  whichkey         wofi cheatsheet of the live sway keybindings
      |
      |Run `cumulus <command> --help` for command-specific usage.
      |""".stripMargin

  private def printUmbrellaHelp(): Unit =
    print(UmbrellaHelp)
