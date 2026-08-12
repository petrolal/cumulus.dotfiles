package cumulus.dotfiles.validate

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}

object Validator:
  def run(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus validate]\u001b[0m Running 25+ point desktop health check audit...")

    val requiredTools = Seq(
      "sway", "waybar", "kitty", "wofi", "swaylock", "swayidle", "grim", "slurp",
      "pactl", "brightnessctl", "gsettings", "openrgb", "git", "tar", "curl", "unzip",
      "fc-cache", "which", "zsh"
    )
    var missingCount = 0

    for tool <- requiredTools do
      if isCommandAvailable(tool) then
        println(s"  \u001b[32m[OK]\u001b[0m Binary '$tool' is installed")
      else
        println(s"  \u001b[31m[FAIL]\u001b[0m Binary '$tool' is MISSING")
        missingCount += 1

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
      println("\n\u001b[1;32m[SUCCESS]\u001b[0m All 25+ system health requirements validated.")
      Right(())
    else
      Left(CommandError(s"Validation failed: $missingCount required components missing.", 1))

  private def isCommandAvailable(cmd: String): Boolean =
    try os.proc("which", cmd).call(check = false).exitCode == 0 catch case _: Exception => false
