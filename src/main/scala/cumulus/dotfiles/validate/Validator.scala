package cumulus.dotfiles.validate

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}

object Validator:
  def run(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus validate]\u001b[0m Running desktop health check...")

    val requiredTools = Seq("sway", "waybar", "kitty", "wofi", "swaylock", "grim", "slurp")
    var missingCount = 0

    for tool <- requiredTools do
      if isCommandAvailable(tool) then
        println(s"  \u001b[32m[OK]\u001b[0m Binary '$tool' is installed")
      else
        println(s"  \u001b[31m[FAIL]\u001b[0m Binary '$tool' is MISSING")
        missingCount += 1

    if os.exists(ctx.configDir / "sway") then
      println(s"  \u001b[32m[OK]\u001b[0m Sway configuration directory exists (${ctx.configDir / "sway"})")
    else
      println(s"  \u001b[31m[FAIL]\u001b[0m Sway config missing at ${ctx.configDir / "sway"}")
      missingCount += 1

    if missingCount == 0 then
      println("\n\u001b[1;32m[SUCCESS]\u001b[0m All system requirements are validated.")
      Right(())
    else
      Left(CommandError(s"Validation failed: $missingCount required components missing.", 1))

  private def isCommandAvailable(cmd: String): Boolean =
    try
      val res = os.proc("which", cmd).call(check = false)
      res.exitCode == 0
    catch
      case _: Exception => false
