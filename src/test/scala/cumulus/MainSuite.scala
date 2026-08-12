package cumulus

import munit.FunSuite

class MainSuite extends FunSuite:
  test("Main.dispatch returns 0 for version"):
    val code = Main.dispatch(Array("version"))
    assertEquals(code, 0)

  test("Main.dispatch returns 0 for -v"):
    val code = Main.dispatch(Array("-v"))
    assertEquals(code, 0)

  test("Main.dispatch returns non-zero for unknown command"):
    val code = Main.dispatch(Array("non-existent-command-12345"))
    assert(code != 0)

  test("Main.dispatch routes sdd command"):
    val code = Main.dispatch(Array("sdd"))
    assertEquals(code, 0)
