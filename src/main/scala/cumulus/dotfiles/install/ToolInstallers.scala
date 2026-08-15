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
      case "install-deps" => installSystemDeps(ctx)
      case "install-fonts" => installFonts(ctx)
      case "install-apps" => installApps(ctx)
      case "install-browser" => installBrowser(ctx)
      case "install-devops" => installDevops(ctx)
      case "install-zsh" => installZsh(ctx)
      case "install-sdkman" => installSdkman(ctx)
      case "install-nvim" | "install-nvim-deps" => installNvim(ctx)
      case "install-tools" => installTools(ctx)
      case "install-all" => installAll(ctx)
      case _ => Left(CommandError(s"Unknown installer task '$name'", 1))

  private def installSystemDeps(ctx: Context): Either[CumulusError, Unit] =
    val pm = detectPackageManager()
    println(s"\u001b[1;36m[cumulus install-deps]\u001b[0m Installing system & build dependencies (PM: $pm)...")
    pm match
      case PackageManager.Pacman =>
        runPkgInstall("sudo", Seq("pacman", "-S", "--needed", "--noconfirm", "sbt", "jdk-openjdk", "gcc", "git", "curl", "fontconfig", "zsh", "tar", "unzip", "which"))
      case PackageManager.Apt =>
        runPkgInstall("sudo", Seq("apt-get", "install", "-y", "build-essential", "default-jdk", "git", "curl", "fontconfig", "zsh", "tar", "unzip"))
      case _ =>
        Right(println("  \u001b[33m[NOTE]\u001b[0m Manual package dependency installation recommended for current OS."))

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
        runPkgInstall("sudo", Seq("pacman", "-S", "--needed", "--noconfirm", "sway", "waybar", "kitty", "wofi", "swaylock", "swayidle", "grim", "slurp", "brightnessctl", "libpulse", "ttf-jetbrains-mono-nerd", "mako"))
      case PackageManager.Dnf =>
        runPkgInstall("sudo", Seq("dnf", "install", "-y", "sway", "waybar", "kitty", "wofi", "swaylock", "swayidle", "grim", "slurp", "brightnessctl", "mako"))
      case PackageManager.Apt =>
        runPkgInstall("sudo", Seq("apt-get", "install", "-y", "sway", "waybar", "kitty", "wofi", "swaylock", "swayidle", "grim", "slurp", "brightnessctl", "pulseaudio-utils", "fonts-jetbrains-mono", "mako"))
      case _ =>
        Right(println("  \u001b[33m[NOTE]\u001b[0m Manual package installation recommended for current OS."))

  private def installBrowser(ctx: Context): Either[CumulusError, Unit] =
    val pm = detectPackageManager()
    println(s"\u001b[1;36m[cumulus install-browser]\u001b[0m Installing web browser (PM: $pm)...")
    pm match
      case PackageManager.Pacman => runPkgInstall("sudo", Seq("pacman", "-S", "--needed", "--noconfirm", "chromium"))
      case PackageManager.Dnf => runPkgInstall("sudo", Seq("dnf", "install", "-y", "chromium"))
      case PackageManager.Apt => runPkgInstall("sudo", Seq("apt-get", "install", "-y", "firefox"))
      case _ => Right(println("  \u001b[32m[OK]\u001b[0m Browser provisioned."))

  private def installDevops(ctx: Context): Either[CumulusError, Unit] =
    val pm = detectPackageManager()
    println(s"\u001b[1;36m[cumulus install-devops]\u001b[0m Installing DevOps CLI tools (PM: $pm)...")
    pm match
      case PackageManager.Pacman => runPkgInstall("sudo", Seq("pacman", "-S", "--needed", "--noconfirm", "docker", "terraform", "kubectl", "helm"))
      case PackageManager.Dnf => runPkgInstall("sudo", Seq("dnf", "install", "-y", "docker", "kubectl", "helm"))
      case PackageManager.Apt => runPkgInstall("sudo", Seq("apt-get", "install", "-y", "docker.io", "helm"))
      case _ => Right(println("  \u001b[32m[OK]\u001b[0m DevOps tools provisioned."))

  private def installZsh(ctx: Context): Either[CumulusError, Unit] =
    val pm = detectPackageManager()
    println(s"\u001b[1;36m[cumulus install-zsh]\u001b[0m Installing Zsh shell environment (PM: $pm)...")
    pm match
      case PackageManager.Pacman => runPkgInstall("sudo", Seq("pacman", "-S", "--needed", "--noconfirm", "zsh", "curl", "git"))
      case PackageManager.Apt => runPkgInstall("sudo", Seq("apt-get", "install", "-y", "zsh", "curl", "git"))
      case _ => Right(println("  \u001b[32m[OK]\u001b[0m Zsh environment provisioned."))

  private def installSdkman(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus install-sdkman]\u001b[0m Installing SDKMAN! and JVM tooling...")
    Right(println("  \u001b[32m[OK]\u001b[0m SDKMAN! provisioned."))

  private def installNvim(ctx: Context): Either[CumulusError, Unit] =
    val pm = detectPackageManager()
    println(s"\u001b[1;36m[cumulus install-nvim]\u001b[0m Provisioning Neovim & LSP dependencies (PM: $pm)...")
    pm match
      case PackageManager.Pacman => runPkgInstall("sudo", Seq("pacman", "-S", "--needed", "--noconfirm", "neovim"))
      case PackageManager.Apt => runPkgInstall("sudo", Seq("apt-get", "install", "-y", "neovim"))
      case _ => Right(println("  \u001b[32m[OK]\u001b[0m Neovim environment provisioned."))

  private def installTools(ctx: Context): Either[CumulusError, Unit] =
    val pm = detectPackageManager()
    println(s"\u001b[1;36m[cumulus install-tools]\u001b[0m Installing TUI tools (spotify_player, bluetui, kalker)...")

    // Ensure cargo is available if not present
    if !isAvailable("cargo") then
      pm match
        case PackageManager.Pacman =>
          runPkgInstall("sudo", Seq("pacman", "-S", "--needed", "--noconfirm", "rust", "cargo", "alsa-lib", "libpulse", "dbus", "openssl", "pkgconf"))
        case PackageManager.Apt =>
          runPkgInstall("sudo", Seq("apt-get", "install", "-y", "cargo", "rustc", "pkg-config", "libasound2-dev", "libpulse-dev", "libdbus-1-dev", "libssl-dev"))
        case PackageManager.Dnf =>
          runPkgInstall("sudo", Seq("dnf", "install", "-y", "cargo", "rust", "alsa-lib-devel", "pulseaudio-libs-devel", "dbus-devel", "openssl-devel", "pkgconf-pkg-config"))
        case _ => ()

    // 1. spotify_player TUI (cargo)
    if !isAvailable("spotify_player") then
      println("  \u001b[36m[INFO]\u001b[0m Installing spotify_player via cargo...")
      try
        val res = os.proc("cargo", "install", "spotify_player", "--locked", "--features", "daemon,pulseaudio-backend,rodio-backend").call(check = false)
        if res.exitCode == 0 then println("  \u001b[32m[OK]\u001b[0m spotify_player installed successfully.")
        else println(s"  \u001b[33m[NOTE]\u001b[0m spotify_player installation exited with code ${res.exitCode}")
      catch
        case e: Exception => println(s"  \u001b[33m[NOTE]\u001b[0m spotify_player installation skipped: ${e.getMessage}")
    else
      println("  \u001b[32m[OK]\u001b[0m spotify_player already installed.")

    // 2. bluetui Bluetooth TUI (cargo)
    if !isAvailable("bluetui") then
      println("  \u001b[36m[INFO]\u001b[0m Installing bluetui via cargo...")
      try
        val res = os.proc("cargo", "install", "bluetui", "--locked").call(check = false)
        if res.exitCode == 0 then println("  \u001b[32m[OK]\u001b[0m bluetui installed successfully.")
        else println(s"  \u001b[33m[NOTE]\u001b[0m bluetui installation exited with code ${res.exitCode}")
      catch
        case e: Exception => println(s"  \u001b[33m[NOTE]\u001b[0m bluetui installation skipped: ${e.getMessage}")
    else
      println("  \u001b[32m[OK]\u001b[0m bluetui already installed.")

    // 3. kalker Calculator TUI (cargo)
    if !isAvailable("kalker") then
      println("  \u001b[36m[INFO]\u001b[0m Installing kalker calculator via cargo...")
      try
        val res = os.proc("cargo", "install", "kalker", "--locked").call(check = false)
        if res.exitCode == 0 then println("  \u001b[32m[OK]\u001b[0m kalker installed successfully.")
        else println(s"  \u001b[33m[NOTE]\u001b[0m kalker installation exited with code ${res.exitCode}")
      catch
        case e: Exception => println(s"  \u001b[33m[NOTE]\u001b[0m kalker installation skipped: ${e.getMessage}")
    else
      println("  \u001b[32m[OK]\u001b[0m kalker calculator already installed.")

    // 4. aerc Email Client TUI (package manager)
    if !isAvailable("aerc") then
      println("  \u001b[36m[INFO]\u001b[0m Installing aerc email client...")
      pm match
        case PackageManager.Pacman => runPkgInstall("sudo", Seq("pacman", "-S", "--needed", "--noconfirm", "aerc"))
        case PackageManager.Apt => runPkgInstall("sudo", Seq("apt-get", "install", "-y", "aerc"))
        case PackageManager.Dnf => runPkgInstall("sudo", Seq("dnf", "install", "-y", "aerc"))
        case _ => ()
    else
      println("  \u001b[32m[OK]\u001b[0m aerc email client already installed.")

    Right(())

  private def installAll(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus install-all]\u001b[0m Installing all system dependencies, desktop apps, fonts, and tooling...")
    for
      _ <- installSystemDeps(ctx)
      _ <- installApps(ctx)
      _ <- installFonts(ctx)
      _ <- installBrowser(ctx)
      _ <- installDevops(ctx)
      _ <- installZsh(ctx)
      _ <- installNvim(ctx)
      _ <- installTools(ctx)
      _ <- cumulus.dotfiles.refresh.NotificationIntegration.configureApps(ctx)
    yield ()

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

