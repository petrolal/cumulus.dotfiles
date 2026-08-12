package cumulus.dotfiles.sdd

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}

object SpecDrivenDev:
  def run(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    println("[1;36m[cumulus sdd][0m Generating AI spec-driven development context...")

    val targetFile = args.headOption.getOrElse("project-context.md")
    val projectContext = if targetFile.startsWith("/") then
      os.Path(targetFile)
    else
      ctx.dotfilesDir / targetFile

    if os.exists(projectContext) then
      val content = os.read(projectContext)
      val lines = content.linesIterator.toList
      val lineCount = lines.length
      val tokenEstimate = estimateTokens(content)

      println(s"  [32m[OK][0m Loaded project context")
      println(s"  [32m[OK][0m File: $projectContext")
      println(s"  [32m[OK][0m Lines: $lineCount")
      println(s"  [32m[OK][0m Estimated tokens: ~$tokenEstimate")
      println(s"  [32m[OK][0m Bytes: ${content.length}")

      val showFull = args.contains("--full")
      val showTokens = args.contains("--tokens")

      if showFull then
        println("\n--- FULL CONTEXT ---")
        println(content)
        println("--- END CONTEXT ---")
      else if showTokens then
        println("\n--- TOKEN BREAKDOWN ---")
        val sections = content.split("\n#{1,6} ").drop(1)
        for section <- sections do
          val sectionName = section.takeWhile(_ != '\n')
          val sectionContent = section.dropWhile(_ != '\n').drop(1)
          val sectionTokens = estimateTokens(sectionContent)
          println(f"  $sectionName%-40s ~$sectionTokens%-5d tokens")
        println("--- END TOKEN BREAKDOWN ---")
      else
        println("\n--- SPEC DRIVEN CONTEXT HEAD (first 30 lines) ---")
        println(lines.take(30).mkString("\n"))
        println("...\n--- END HEAD ---")
        println("\nUse --full to see all content, --tokens for token breakdown")

      Right(())
    else
      Left(CommandError(s"Project context file missing at $projectContext", 1))

  private def estimateTokens(text: String): Int =
    val words = text.split("\\s+").length
    (text.length / 4) max ((words * 1.3).toInt)
