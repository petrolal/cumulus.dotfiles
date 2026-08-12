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
      case "theme" => Right(println(s"[cumulus] module 'theme' invoked (placeholder)"))
      case "runtime-refresh" => Right(println(s"[cumulus] module 'runtime-refresh' invoked (placeholder)"))
      case "os-colorscheme" => Right(println(s"[cumulus] module 'os-colorscheme' invoked (placeholder)"))
      case "rgb-theme" => Right(println(s"[cumulus] module 'rgb-theme' invoked (placeholder)"))
      case "lock" => Right(println(s"[cumulus] module 'lock' invoked (placeholder)"))
      case "idle" => Right(println(s"[cumulus] module 'idle' invoked (placeholder)"))
      case "screenshot" => Right(println(s"[cumulus] module 'screenshot' invoked (placeholder)"))
      case "autotiling" => Right(println(s"[cumulus] module 'autotiling' invoked (placeholder)"))
      case "validate" => Right(println(s"[cumulus] module 'validate' invoked (placeholder)"))
      case "backup" => Right(println(s"[cumulus] module 'backup' invoked (placeholder)"))
      case "restore" => Right(println(s"[cumulus] module 'restore' invoked (placeholder)"))
      case "update" => Right(println(s"[cumulus] module 'update' invoked (placeholder)"))
      case "sdd" => Right(println(s"[cumulus] module 'sdd' invoked (placeholder)"))
      case "install" | "deploy" => Right(println(s"[cumulus] module 'install' invoked (placeholder)"))
      case "install-fonts" | "install-apps" | "install-browser" | "install-devops" |
           "install-zsh" | "install-sdkman" | "install-nvim" | "install-nvim-deps" =>
        Right(println(s"[cumulus] module '$name' invoked (placeholder)"))
      case "theme-picker" | "whichkey" =>
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
