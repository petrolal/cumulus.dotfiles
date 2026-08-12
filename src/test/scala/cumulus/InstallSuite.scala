package cumulus

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.install.{DeployInstaller, ToolInstallers}
import munit.FunSuite

class InstallSuite extends FunSuite:
  test("DeployInstaller.run executes symlink deployment and writes manifest"):
    val ctx = Context.discover().toOption.get
    val res = DeployInstaller.run(ctx, Nil)
    assert(res.isRight)
    assert(os.exists(ctx.shareDir / "manifest.json"))

  test("ToolInstallers.runTool executes fonts installer task"):
    val ctx = Context.discover().toOption.get
    val res = ToolInstallers.runTool("install-fonts", ctx, Nil)
    assert(res.isRight)
