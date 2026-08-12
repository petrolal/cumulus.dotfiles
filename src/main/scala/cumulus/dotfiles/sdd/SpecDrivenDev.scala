package cumulus.dotfiles.sdd

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}

object SpecDrivenDev:
  def run(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    println("\u001b[1;36m[cumulus sdd]\u001b[0m Generating AI spec-driven development context...")
    val projectContext = ctx.dotfilesDir / "project-context.md"

    if os.exists(projectContext) then
      val content = os.read(projectContext)
      println(s"  \u001b[32m[OK]\u001b[0m Loaded project context (${content.linesIterator.size} lines)")
      println("\n--- SPEC DRIVEN CONTEXT HEAD ---")
      println(content.linesIterator.take(20).mkString("\n"))
      println("...\n--- END HEAD ---")
      Right(())
    else
      Left(CommandError(s"Project context file missing at $projectContext", 1))
