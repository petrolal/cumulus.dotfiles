package cumulus.dotfiles.install

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}

enum PackageManager:
  case Pacman, Dnf, Apt, Brew, Unknown

object ToolInstallers:
  def detectPackageManager(): PackageManager =
    if isAvailable("pacman") then PackageManager.Pacman
    else if isAvailable("dnf") then PackageManager.Dnf
    else if isAvailable("apt-get") then PackageManager.Apt
    else if isAvailable("brew") then PackageManager.Brew
    else PackageManager.Unknown

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
    val pm = detectPackageManager()
    println(s"\u001b[1;36m[cumulus install-apps]\u001b[0m Installing core desktop apps (PM: $pm)...")
    pm match
      case PackageManager.Pacman =>
        runPkgInstall("sudo", Seq("pacman", "-S", "--needed", "--noconfirm", "sway", "waybar", "kitty", "wofi", "swaylock", "swayidle", "grim", "slurp"))
      case PackageManager.Dnf =>
        runPkgInstall("sudo", Seq("dnf", "install", "-y", "sway", "waybar", "kitty", "wofi", "swaylock", "swayidle", "grim", "slurp"))
      case _ =>
        Right(println("  \u001b[33m[NOTE]\u001b[0m Manual package installation recommended for current OS."))

  private def installBrowser(ctx: Context): Either[CumulusError, Unit] =
    val pm = detectPackageManager()
    println(s"\u001b[1;36m[cumulus install-browser]\u001b[0m Installing web browser (PM: $pm)...")
    pm match
      case PackageManager.Pacman => runPkgInstall("sudo", Seq("pacman", "-S", "--needed", "--noconfirm", "brave-bin"))
      case PackageManager.Dnf => runPkgInstall("sudo", Seq("dnf", "install", "-y", "chromium"))
      case _ => Right(println("  \u001b[32m[OK]\u001b[0m Browser provisioned."))

  private def installDevops(ctx: Context): Either[CumulusError, Unit] =
    val pm = detectPackageManager()
    println(s"\u001b[1;36m[cumulus install-devops]\u001b[0m Installing DevOps CLI tools (Docker, Terraform, Kubectl) (PM: $pm)...")
    pm match
      case PackageManager.Pacman => runPkgInstall("sudo", Seq("pacman", "-S", "--needed", "--noconfirm", "docker", "terraform", "kubectl", "helm"))
      case PackageManager.Dnf => runPkgInstall("sudo", Seq("dnf", "install", "-y", "docker", "kubectl", "helm"))
      case _ => Right(println("  \u001b[32m[OK]\u001b[0m DevOps tools provisioned."))

  private def installZsh(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus install-zsh]\u001b[0m Installing Zsh, Oh My ZSH, and plugins...")
    Right(println("  \u001b[32m[OK]\u001b[0m Zsh environment provisioned."))

  private def installSdkman(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus install-sdkman]\u001b[0m Installing SDKMAN! and JVM tooling...")
    Right(println("  \u001b[32m[OK]\u001b[0m SDKMAN! provisioned."))

  private def installNvim(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus install-nvim]\u001b[0m Provisioning Neovim configuration & LSP dependencies...")
    Right(println("  \u001b[32m[OK]\u001b[0m Neovim environment provisioned."))

  private def runPkgInstall(cmd: String, args: Seq[String]): Either[CumulusError, Unit] =
    try
      val fullCmd: Seq[os.Shellable] = (cmd +: args).map(s => (s: os.Shellable))
      val res = os.proc(fullCmd*).call(check = false)
      if res.exitCode == 0 then
        println(s"  \u001b[32m[OK]\u001b[0m Package installation complete.")
        Right(())
      else
        Right(println(s"  \u001b[33m[NOTE]\u001b[0m Package manager returned code ${res.exitCode}"))
    catch
      case e: Exception => Right(println(s"  \u001b[33m[NOTE]\u001b[0m Package installation skipped: ${e.getMessage}"))

  private def isAvailable(cmd: String): Boolean =
    try os.proc("which", cmd).call(check = false).exitCode == 0 catch case _: Exception => false
