package cumulus

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CumulusError, UnknownCommandError}

object Main:
  def main(args: Array[String]): Unit =
    val exitCode = dispatch(args)
    if exitCode != 0 then sys.exit(exitCode)

  def dispatch(args: Array[String]): Int =
    val rawProg = sys.env.getOrElse("CUMULUS_PROG_NAME", "")
    val progName = if rawProg.nonEmpty then rawProg else args.headOption.getOrElse("cumulus")
    val binaryBasename = os.Path(progName, os.pwd).last

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

  private def runCommand(name: String, args: List[String]): Either[CumulusError, Unit] =
    for
      ctx <- Context.discover()
      res <- dispatchModule(name, ctx, args)
    yield res

  private def dispatchModule(name: String, ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    name match
      case "validate" => cumulus.dotfiles.validate.Validator.run(ctx, args)
      case "sdd" => cumulus.dotfiles.sdd.SpecDrivenDev.run(ctx, args)
      case "lock" => cumulus.dotfiles.sysutils.SysUtils.runLock(ctx)
      case "idle" => cumulus.dotfiles.sysutils.SysUtils.runIdle(ctx)
      case "screenshot" => cumulus.dotfiles.sysutils.SysUtils.runScreenshot(ctx, args)
      case "theme" => cumulus.dotfiles.theme.ThemeEngine.run(ctx, args)
      case "runtime-refresh" => cumulus.dotfiles.refresh.RefreshEngine.runRefresh(ctx)
      case "os-colorscheme" => cumulus.dotfiles.refresh.RefreshEngine.runOsColorscheme(ctx)
      case "rgb-theme" => cumulus.dotfiles.refresh.RefreshEngine.runRgbTheme(ctx, args)
      case "autotiling" => cumulus.dotfiles.autotiling.AutotilingDaemon.run(ctx, args)
      case "theme-picker" => cumulus.dotfiles.pickers.WofiPickers.runThemePicker(ctx, args)
      case "whichkey" => cumulus.dotfiles.pickers.WofiPickers.runWhichkey(ctx, args)
      case "backup" => cumulus.dotfiles.maintenance.Maintenance.runBackup(ctx, args)
      case "restore" => cumulus.dotfiles.maintenance.Maintenance.runRestore(ctx, args)
      case "update" => cumulus.dotfiles.maintenance.Maintenance.runUpdate(ctx, args)
      case "install" | "deploy" => Right(println(s"[cumulus] module 'install' invoked (placeholder)"))
      case "install-fonts" | "install-apps" | "install-browser" | "install-devops" |
           "install-zsh" | "install-sdkman" | "install-nvim" | "install-nvim-deps" =>
        Right(println(s"[cumulus] module '$name' invoked (placeholder)"))
        Right(println(s"[cumulus] module '$name' invoked (placeholder)"))
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
      |  runtime-refresh  refresh running apps (sway/waybar/kitty/wofi/neovim/os/rgb)
      |  os-colorscheme   sync the GNOME/GTK color-scheme setting
      |  rgb-theme        sync hardware RGB lighting with the active theme color
      |  lock             lock the screen (swaylock) styled to the active theme
      |  idle             run the swayidle daemon (auto-lock, dpms, suspend)
      |  screenshot       capture a screenshot (full|region|window)
      |  autotiling       Fibonacci spiral autotiling daemon for Sway
      |  validate         read-only health check of the deployed setup
      |  backup           snapshot managed configs to a timestamped tarball
      |  restore          restore a snapshot created by backup
      |  update           git pull the dotfiles and re-run the installer
      |  sdd              token-efficient spec-driven development for AI workflows
      |  install-fonts    install the JetBrainsMono Nerd Font
      |
      |  install-apps     install core desktop apps (sway/waybar/kitty/etc.)
      |  install-browser  install a web browser (brave/chromium)
      |  install-devops   install devops tooling (docker/terraform/kubectl/etc.)
      |  install-zsh      install zsh + oh-my-zsh + plugins and set the shell
      |  install-sdkman   install SDKMAN! and JVM tooling
      |  install-nvim     install the Neovim config dependencies (deploy)
      |  install-nvim-deps install Neovim + its plugin ecosystem dependencies
      |  theme-picker     wofi GUI front-end for the theme command
      |  whichkey         wofi cheatsheet of the live sway keybindings
      |
      |Run `cumulus <command> --help` for command-specific usage.
      |""".stripMargin

  private def printUmbrellaHelp(): Unit =
    print(UmbrellaHelp)
