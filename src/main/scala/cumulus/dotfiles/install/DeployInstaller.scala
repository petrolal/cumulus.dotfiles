package cumulus.dotfiles.install

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}

object DeployInstaller:
  def run(ctx: Context, args: List[String]): Either[CumulusError, Unit] =
    println("\u001b[1;32m[cumulus install]\u001b[0m Deploying cumulus.dotfiles configurations & symlinks...")
    val binDir = ctx.home / ".local" / "bin"
    os.makeDir.all(binDir)
    
    val binaryPath = binDir / "cumulus"
    println(s"  \u001b[32m[OK]\u001b[0m Multi-call executable target: $binaryPath")
    Right(())
