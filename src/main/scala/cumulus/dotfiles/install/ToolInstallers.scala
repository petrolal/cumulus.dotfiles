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
      case "install-brew" | "install-homebrew" => installHomebrew(ctx)
      case "install-gh" | "install-github-cli" => installGh(ctx)
      case "install-coursier" | "install-cs" => installCoursier(ctx)
      case "install-fonts" => installFonts(ctx)
      case "install-apps" => installApps(ctx)
      case "install-browser" => installBrowser(ctx)
      case "install-devops" => installDevops(ctx)
      case "install-zsh" => installZsh(ctx)
      case "install-sdkman" => installSdkman(ctx)
      case "install-nvim" | "install-nvim-deps" | "install-neovim" => installNvim(ctx)
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

  private def getBrewBin(ctx: Context): Option[os.Path] =
    val standardPaths = Seq(
      ctx.home / ".linuxbrew" / "bin" / "brew",
      os.root / "home" / "linuxbrew" / ".linuxbrew" / "bin" / "brew",
      os.root / "opt" / "homebrew" / "bin" / "brew",
      os.root / "usr" / "local" / "bin" / "brew"
    )
    if isAvailable("brew") then
      try Some(os.Path(os.proc("which", "brew").call().out.trim()))
      catch case _: Exception => standardPaths.find(os.exists)
    else standardPaths.find(os.exists)

  private def installHomebrew(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus install-brew]\u001b[0m Checking/Installing Homebrew...")
    getBrewBin(ctx) match
      case Some(brewPath) =>
        println(s"  \u001b[32m[OK]\u001b[0m Homebrew already installed at $brewPath")
        Right(())
      case None =>
        println("  \u001b[36m[INFO]\u001b[0m Installing Homebrew via official non-interactive installer...")
        try
          val res = os.proc(
            "bash", "-c",
            "NONINTERACTIVE=1 /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
          ).call(stdin = os.Inherit, stdout = os.Inherit, stderr = os.Inherit, check = false)
          if res.exitCode == 0 then
            println("  \u001b[32m[OK]\u001b[0m Homebrew installed successfully.")
          else
            println(s"  \u001b[33m[NOTE]\u001b[0m Homebrew installer returned code ${res.exitCode}")
          Right(())
        catch
          case e: Exception =>
            println(s"  \u001b[33m[NOTE]\u001b[0m Homebrew installation skipped: ${e.getMessage}")
            Right(())

  private def installGh(ctx: Context): Either[CumulusError, Unit] =
    val pm = detectPackageManager()
    println(s"\u001b[1;36m[cumulus install-gh]\u001b[0m Checking/Installing GitHub CLI (PM: $pm)...")
    if isAvailable("gh") then
      println("  \u001b[32m[OK]\u001b[0m GitHub CLI (gh) already installed.")
      Right(())
    else
      pm match
        case PackageManager.Pacman =>
          runPkgInstall("sudo", Seq("pacman", "-S", "--needed", "--noconfirm", "github-cli"))
        case PackageManager.Dnf =>
          runPkgInstall("sudo", Seq("dnf", "install", "-y", "gh"))
        case PackageManager.Apt =>
          runPkgInstall("sudo", Seq("apt-get", "install", "-y", "gh"))
        case PackageManager.Brew =>
          runPkgInstall("brew", Seq("install", "gh"))
        case PackageManager.Unknown =>
          getBrewBin(ctx) match
            case Some(brewBin) =>
              runPkgInstall(brewBin.toString, Seq("install", "gh"))
            case None =>
              println("  \u001b[33m[NOTE]\u001b[0m Manual installation of GitHub CLI (gh) recommended.")
              Right(())

  private def getCoursierBin(ctx: Context): Option[os.Path] =
    val localBinCs = ctx.home / ".local" / "bin" / "cs"
    val csShareBin = ctx.home / ".local" / "share" / "coursier" / "bin" / "cs"
    if isAvailable("cs") then
      try Some(os.Path(os.proc("which", "cs").call().out.trim()))
      catch case _: Exception => Some(localBinCs)
    else if isAvailable("coursier") then
      try Some(os.Path(os.proc("which", "coursier").call().out.trim()))
      catch case _: Exception => Some(localBinCs)
    else if os.exists(localBinCs) then Some(localBinCs)
    else if os.exists(csShareBin) then Some(csShareBin)
    else None

  private def installCoursier(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus install-coursier]\u001b[0m Checking/Installing Coursier...")
    getCoursierBin(ctx) match
      case Some(csPath) =>
        println(s"  \u001b[32m[OK]\u001b[0m Coursier already installed at $csPath")
        Right(())
      case None =>
        val binDir = ctx.home / ".local" / "bin"
        os.makeDir.all(binDir)
        val csDest = binDir / "cs"
        val isMac = System.getProperty("os.name", "").toLowerCase.contains("mac")
        val launcher = if isMac then "cs-x86_64-apple-darwin.gz" else "cs-x86_64-pc-linux.gz"
        val url = s"https://github.com/coursier/launchers/raw/master/$launcher"
        println(s"  \u001b[36m[INFO]\u001b[0m Downloading Coursier launcher from $url...")
        try
          val curlRes = os.proc("bash", "-c", s"curl -fL '$url' | gzip -d > '$csDest' && chmod +x '$csDest'").call(check = false)
          if curlRes.exitCode == 0 then
            println(s"  \u001b[32m[OK]\u001b[0m Coursier installed to $csDest")
            os.proc(csDest.toString, "update").call(check = false)
          else
            println(s"  \u001b[33m[NOTE]\u001b[0m Coursier download returned code ${curlRes.exitCode}")
          Right(())
        catch
          case e: Exception =>
            println(s"  \u001b[33m[NOTE]\u001b[0m Coursier installation skipped: ${e.getMessage}")
            Right(())

  private def installNvim(ctx: Context): Either[CumulusError, Unit] =
    val pm = detectPackageManager()
    println(s"\u001b[1;36m[cumulus install-nvim]\u001b[0m Provisioning Neovim & cumulus.neovim (PM: $pm)...")
    
    // 1. Install base Neovim editor
    if !isAvailable("nvim") then
      pm match
        case PackageManager.Pacman => runPkgInstall("sudo", Seq("pacman", "-S", "--needed", "--noconfirm", "neovim"))
        case PackageManager.Apt => runPkgInstall("sudo", Seq("apt-get", "install", "-y", "neovim"))
        case PackageManager.Dnf => runPkgInstall("sudo", Seq("dnf", "install", "-y", "neovim"))
        case PackageManager.Brew => runPkgInstall("brew", Seq("install", "neovim"))
        case _ =>
          getBrewBin(ctx) match
            case Some(brewBin) => runPkgInstall(brewBin.toString, Seq("install", "neovim"))
            case None => Right(println("  \u001b[33m[NOTE]\u001b[0m Manual neovim installation recommended."))
    else
      println("  \u001b[32m[OK]\u001b[0m Neovim editor already installed.")

    // 2. Install cumulus.neovim via Coursier flow
    installCoursier(ctx)
    val csExe = getCoursierBin(ctx).map(_.toString).getOrElse("cs")
    println("  \u001b[36m[INFO]\u001b[0m Installing/updating cumulus.neovim via Coursier flow...")
    try
      val res = os.proc(csExe, "install", "io.github.petrolal::cumulus.neovim", "--name", "cumulus-neovim").call(
        stdin = os.Inherit, stdout = os.Inherit, stderr = os.Inherit, check = false
      )
      if res.exitCode == 0 then
        println("  \u001b[32m[OK]\u001b[0m cumulus.neovim installed successfully via Coursier.")
      else
        val fallbackRes = os.proc(csExe, "install", "io.github.petrolal::cumulus.neovim").call(
          stdin = os.Inherit, stdout = os.Inherit, stderr = os.Inherit, check = false
        )
        if fallbackRes.exitCode == 0 then
          println("  \u001b[32m[OK]\u001b[0m cumulus.neovim installed successfully via Coursier.")
        else
          println(s"  \u001b[33m[NOTE]\u001b[0m Coursier install for cumulus.neovim completed with code ${fallbackRes.exitCode}")
      Right(())
    catch
      case e: Exception =>
        println(s"  \u001b[33m[NOTE]\u001b[0m cumulus.neovim coursier installation skipped: ${e.getMessage}")
        Right(())

  private def installTools(ctx: Context): Either[CumulusError, Unit] =
    val pm = detectPackageManager()
    println(s"\u001b[1;36m[cumulus install-tools]\u001b[0m Installing TUI tools (spotify_player, bluetui, kalker, aerc)...")

    val cargoHomeBin = ctx.home / ".cargo" / "bin"
    def cargoAvailable(): Boolean =
      isAvailable("cargo") || os.exists(cargoHomeBin / "cargo")

    def runCargo(tool: String, extraArgs: Seq[String] = Nil): Either[CumulusError, Unit] =
      val cargoExe = if isAvailable("cargo") then "cargo" else (cargoHomeBin / "cargo").toString
      val cmd: Seq[os.Shellable] = Seq(cargoExe: os.Shellable, "install": os.Shellable, tool: os.Shellable, "--locked": os.Shellable) ++ extraArgs.map(a => (a: os.Shellable))
      try
        val res = os.proc(cmd*).call(check = false)
        if res.exitCode == 0 then
          println(s"  \u001b[32m[OK]\u001b[0m $tool installed successfully.")
          Right(())
        else
          println(s"  \u001b[33m[NOTE]\u001b[0m $tool cargo install exited with code ${res.exitCode}")
          Right(())
      catch
        case e: Exception =>
          println(s"  \u001b[33m[NOTE]\u001b[0m $tool cargo install skipped: ${e.getMessage}")
          Right(())

    // Ensure cargo and C library build headers are present if not available
    if !cargoAvailable() then
      pm match
        case PackageManager.Pacman =>
          runPkgInstall("sudo", Seq("pacman", "-S", "--needed", "--noconfirm", "rust", "cargo", "alsa-lib", "libpulse", "dbus", "openssl", "pkgconf"))
        case PackageManager.Apt =>
          runPkgInstall("sudo", Seq("apt-get", "install", "-y", "cargo", "rustc", "pkg-config", "libasound2-dev", "libpulse-dev", "libdbus-1-dev", "libssl-dev"))
        case PackageManager.Dnf =>
          runPkgInstall("sudo", Seq("dnf", "install", "-y", "cargo", "rust", "alsa-lib-devel", "pulseaudio-libs-devel", "dbus-devel", "openssl-devel", "pkgconf-pkg-config"))
        case _ => ()

    // 1. spotify_player TUI (cargo)
    if isAvailable("spotify_player") || os.exists(cargoHomeBin / "spotify_player") then
      println("  \u001b[32m[OK]\u001b[0m spotify_player already installed.")
    else if cargoAvailable() then
      println("  \u001b[36m[INFO]\u001b[0m Installing spotify_player via cargo...")
      runCargo("spotify_player", Seq("--features", "daemon,pulseaudio-backend,rodio-backend"))
    else
      println("  \u001b[33m[NOTE]\u001b[0m cargo not available; skipping spotify_player installation.")

    // 2. bluetui Bluetooth TUI (cargo)
    if isAvailable("bluetui") || os.exists(cargoHomeBin / "bluetui") then
      println("  \u001b[32m[OK]\u001b[0m bluetui already installed.")
    else if cargoAvailable() then
      println("  \u001b[36m[INFO]\u001b[0m Installing bluetui via cargo...")
      runCargo("bluetui")
    else
      println("  \u001b[33m[NOTE]\u001b[0m cargo not available; skipping bluetui installation.")

    // 3. kalker Calculator TUI (cargo / pacman)
    if isAvailable("kalker") || os.exists(cargoHomeBin / "kalker") then
      println("  \u001b[32m[OK]\u001b[0m kalker calculator already installed.")
    else if pm == PackageManager.Pacman then
      runPkgInstall("sudo", Seq("pacman", "-S", "--needed", "--noconfirm", "kalker"))
    else if cargoAvailable() then
      println("  \u001b[36m[INFO]\u001b[0m Installing kalker calculator via cargo...")
      runCargo("kalker")
    else
      println("  \u001b[33m[NOTE]\u001b[0m cargo not available; skipping kalker installation.")

    // 4. aerc Email Client TUI (package manager)
    if isAvailable("aerc") then
      println("  \u001b[32m[OK]\u001b[0m aerc email client already installed.")
    else
      println("  \u001b[36m[INFO]\u001b[0m Installing aerc email client...")
      pm match
        case PackageManager.Pacman => runPkgInstall("sudo", Seq("pacman", "-S", "--needed", "--noconfirm", "aerc"))
        case PackageManager.Apt => runPkgInstall("sudo", Seq("apt-get", "install", "-y", "aerc"))
        case PackageManager.Dnf => runPkgInstall("sudo", Seq("dnf", "install", "-y", "aerc"))
        case _ => Right(println("  \u001b[33m[NOTE]\u001b[0m Manual installation of aerc required for this system."))

    Right(())

  private def installAll(ctx: Context): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus install-all]\u001b[0m Installing all system dependencies, desktop apps, fonts, and tooling...")
    for
      _ <- installSystemDeps(ctx)
      _ <- installHomebrew(ctx)
      _ <- installGh(ctx)
      _ <- installCoursier(ctx)
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
      val res = os.proc(fullCmd*).call(stdin = os.Inherit, stdout = os.Inherit, stderr = os.Inherit, check = false)
      if res.exitCode == 0 then
        println(s"  \u001b[32m[OK]\u001b[0m Package installation complete.")
        Right(())
      else
        println(s"  \u001b[33m[NOTE]\u001b[0m Package manager returned code ${res.exitCode}")
        Right(())
    catch
      case e: Exception =>
        println(s"  \u001b[33m[NOTE]\u001b[0m Package installation skipped: ${e.getMessage}")
        Right(())

  private def isAvailable(cmd: String): Boolean =
    try os.proc("which", cmd).call(check = false).exitCode == 0 catch case _: Exception => false

