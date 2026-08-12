package cumulus.dotfiles.validate

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}

object Validator:
  val Subcommands: Seq[String] = Seq(
    "theme", "runtime-refresh", "os-colorscheme", "rgb-theme", "lock", "idle",
    "screenshot", "autotiling", "validate", "backup", "restore", "update",
    "sdd", "install", "deploy", "install-fonts", "install-apps", "install-browser",
    "install-devops", "install-zsh", "install-sdkman", "install-nvim",
    "install-nvim-deps", "theme-picker", "whichkey"
  )

  def run(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus validate]\u001b[0m Running 25+ point desktop health & symlink audit...")

    var missingCount = 0

    // 1. Audit Desktop CLI Tools
    println("\n\u001b[1m--- System Binary Audit ---\u001b[0m")
    val requiredTools = Seq(
      "sway", "waybar", "kitty", "wofi", "swaylock", "swayidle", "grim", "slurp",
      "pactl", "brightnessctl", "gsettings", "openrgb", "git", "tar", "curl", "unzip",
      "fc-cache", "which", "zsh"
    )

    for tool <- requiredTools do
      if isCommandAvailable(tool) then
        println(s"  \u001b[32m[OK]\u001b[0m Binary '$tool' is installed")
      else
        println(s"  \u001b[31m[FAIL]\u001b[0m Binary '$tool' is MISSING")
        missingCount += 1

    // 2. Audit Subcommand Binary Symlinks in ~/.local/bin/
    println("\n\u001b[1m--- Subcommand Symlink Audit (~/.local/bin/) ---\u001b[0m")
    val binDir = ctx.home / ".local" / "bin"
    val mainBinary = binDir / "cumulus"

    if os.exists(mainBinary) then
      println(s"  \u001b[32m[OK]\u001b[0m Main executable target: $mainBinary")
    else
      println(s"  \u001b[31m[FAIL]\u001b[0m Main executable missing at $mainBinary")
      missingCount += 1

    for cmd <- Subcommands do
      val symlinkPath = binDir / s"cumulus-$cmd"
      if os.exists(symlinkPath) || os.isLink(symlinkPath) then
        println(s"  \u001b[32m[OK]\u001b[0m Symlink 'cumulus-$cmd' -> $mainBinary")
      else
        println(s"  \u001b[31m[FAIL]\u001b[0m Symlink 'cumulus-$cmd' is MISSING at $symlinkPath")
        missingCount += 1

    // 3. Audit Desktop Config Paths
    println("\n\u001b[1m--- Desktop Configuration Paths ---\u001b[0m")
    val requiredPaths = Seq(
      ctx.configDir / "sway",
      ctx.configDir / "kitty",
      ctx.configDir / "waybar",
      ctx.configDir / "wofi"
    )

    for path <- requiredPaths do
      if os.exists(path) then
        println(s"  \u001b[32m[OK]\u001b[0m Path exists: $path")
      else
        println(s"  \u001b[31m[FAIL]\u001b[0m Path MISSING: $path")
        missingCount += 1

    val fontsDir = ctx.home / ".local" / "share" / "fonts"
    if os.exists(fontsDir) then
      println(s"  \u001b[32m[OK]\u001b[0m User fonts directory exists ($fontsDir)")
    else
      println(s"  \u001b[33m[NOTE]\u001b[0m User fonts directory not created yet ($fontsDir)")

    if missingCount == 0 then
      println("\n\u001b[1;32m[SUCCESS]\u001b[0m All system binaries, configuration paths, and subcommand symlinks validated!")
      Right(())
    else
      Left(CommandError(s"Validation failed: $missingCount required components missing.", 1))

  private def isCommandAvailable(cmd: String): Boolean =
    try os.proc("which", cmd).call(check = false).exitCode == 0 catch case _: Exception => false
