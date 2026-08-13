package cumulus

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.install.{DeployInstaller, ToolInstallers, Manifest, ManifestEntry}
import munit.FunSuite

class InstallSuite extends FunSuite:
  private val isCI = sys.env.contains("CI") || sys.env.contains("GITHUB_ACTIONS")

  test("DeployInstaller.run executes symlink deployment and writes manifest"):
    val ctx = Context.discover().toOption.get
    val res = DeployInstaller.run(ctx, List("--links-only"))
    assert(res.isRight)
    assert(os.exists(ctx.shareDir / "manifest.json"))

  test("DeployInstaller creates ~/.local/bin directory"):
    val ctx = Context.discover().toOption.get
    DeployInstaller.run(ctx, List("--links-only"))
    assert(os.exists(ctx.home / ".local" / "bin"))

  test("DeployInstaller creates symlinks for zsh config"):
    assume(!isCI)
    val ctx = Context.discover().toOption.get
    DeployInstaller.run(ctx, List("--links-only"))
    val zshrcLink = ctx.home / ".zshrc"
    assert(os.exists(zshrcLink) || os.isLink(zshrcLink))

  test("DeployInstaller writes valid manifest JSON"):
    assume(!isCI)
    val ctx = Context.discover().toOption.get
    DeployInstaller.run(ctx, List("--links-only"))
    val manifestFile = ctx.shareDir / "manifest.json"
    if os.exists(manifestFile) then
      val json = os.read(manifestFile)
      assert(json.contains("\"sourcePath\""))

  test("ManifestEntry serializes to JSON"):
    val entry = ManifestEntry(
      sourcePath = "/path/to/source",
      targetPath = "/path/to/target",
      backupPath = Some("/path/to/backup")
    )
    val json = upickle.default.write(entry)
    assert(json.contains("sourcePath"))

  test("ToolInstallers.runTool executes fonts installer task"):
    assume(!isCI)
    val ctx = Context.discover().toOption.get
    val res = ToolInstallers.runTool("install-fonts", ctx, Nil)
    assert(res.isRight)

  test("ToolInstallers.runTool rejects invalid tools"):
    val ctx = Context.discover().toOption.get
    val res = ToolInstallers.runTool("install-invalid-tool-xyz", ctx, Nil)
    assert(res.isLeft)

  test("ToolInstallers.detectPackageManager returns valid PM"):
    val pm = ToolInstallers.detectPackageManager()
    assert(pm.toString.nonEmpty)
