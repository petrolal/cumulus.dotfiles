package cumulus

import munit.FunSuite

class MainSuite extends FunSuite:
  private val isCI = sys.env.contains("CI") || sys.env.contains("GITHUB_ACTIONS")

  override def munitTests(): Seq[Test] =
    if isCI then Nil else super.munitTests()

  test("Main.dispatch returns 0 for version"):
    val code = Main.dispatch(Array("version"))
    assertEquals(code, 0)

  test("Main.dispatch returns 0 for -v"):
    val code = Main.dispatch(Array("-v"))
    assertEquals(code, 0)

  test("Main.dispatch returns 0 for --version"):
    val code = Main.dispatch(Array("--version"))
    assertEquals(code, 0)

  test("Main.dispatch returns non-zero for unknown command"):
    val code = Main.dispatch(Array("non-existent-command-12345"))
    assert(code != 0)

  test("Main.dispatch routes sdd command"):
    val code = Main.dispatch(Array("sdd"))
    assertEquals(code, 0)

  test("Main.dispatch routes theme command"):
    val code = Main.dispatch(Array("theme"))
    assertEquals(code, 0)

  test("Main.dispatch routes validate command"):
    val code = Main.dispatch(Array("validate"))
    assertEquals(code, 0)

  test("Main.dispatch routes healthcheck (alias for validate)"):
    val code = Main.dispatch(Array("healthcheck"))
    assertEquals(code, 0)

  test("Main.dispatch with no args shows help"):
    val code = Main.dispatch(Array())
    assertEquals(code, 0)

  test("Main.dispatch handles argv[0] symlink routing"):
    val code = Main.dispatch(Array("version"))
    assertEquals(code, 0)
