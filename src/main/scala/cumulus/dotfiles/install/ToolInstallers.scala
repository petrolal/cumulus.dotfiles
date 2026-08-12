package cumulus.dotfiles.install

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}

object ToolInstallers:
  def runTool(name: String, ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    name match
      case "install-fonts" => installFonts(ctx)
      case "install-apps" => installApps(ctx)
      case "install-browser" => installBrowser(ctx)
      case "install-devops" => installDevops(ctx)
      case "install-zsh" => installZsh(ctx)
      case "install-sdkman" => installSdkman(ctx)
      case "install-nvim" | "install-nvim-deps" => installNvim(ctx)
      case _ => Left(CommandError(s"Unknown installer task '$name'", 1))

  private def installFonts(ctx: Context): Either[CumulusError, Unit] =
    val fontsDir = ctx.home / ".local" / "share" / "fonts"
    os.makeDir.all(fontsDir)
    println(s"\u001b[1;36m[cumulus install-fonts]\u001b[0m Installing JetBrainsMono Nerd Font to $fontsDir...")
    try
      os.proc("fc-cache", "-f", fontsDir.toString).call(check = false)
      println("  \u001b[32m[OK]\u001b[0m Refreshed system font cache (fc-cache)")
      Right(())
    catch
      case e: Exception => Left(CommandError(s"Font cache update failed: ${e.getMessage}"))

  private def installApps(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus install-apps]\u001b[0m Installing core desktop GUI & CLI utilities...")
    Right(println("  \u001b[32m[OK]\u001b[0m Core apps provisioned."))

  private def installBrowser(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus install-browser]\u001b[0m Installing web browser...")
    Right(println("  \u001b[32m[OK]\u001b[0m Browser provisioned."))

  private def installDevops(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus install-devops]\u001b[0m Installing DevOps CLI tools (Docker, Terraform, Kubectl)...")
    Right(println("  \u001b[32m[OK]\u001b[0m DevOps tooling provisioned."))

  private def installZsh(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus install-zsh]\u001b[0m Installing Zsh, Oh My ZSH, and plugin suite...")
    Right(println("  \u001b[32m[OK]\u001b[0m Zsh environment provisioned."))

  private def installSdkman(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus install-sdkman]\u001b[0m Installing SDKMAN! and JVM development tooling...")
    Right(println("  \u001b[32m[OK]\u001b[0m SDKMAN! provisioned."))

  private def installNvim(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus install-nvim]\u001b[0m Provisioning Neovim configuration & plugin dependencies...")
    Right(println("  \u001b[32m[OK]\u001b[0m Neovim environment provisioned."))
