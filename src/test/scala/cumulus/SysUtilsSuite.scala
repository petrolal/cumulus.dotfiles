package cumulus

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.sysutils.SysUtils
import munit.FunSuite

class SysUtilsSuite extends FunSuite:
  test("SysUtils.runLock handles lock call gracefully"):
    val ctx = Context.discover().toOption.get
    val res = SysUtils.runLock(ctx)
    assert(res.isRight)

  test("SysUtils.runIdle handles idle call gracefully"):
    val ctx = Context.discover().toOption.get
    val res = SysUtils.runIdle(ctx)
    assert(res.isRight)

  test("SysUtils.runScreenshot handles invalid mode gracefully"):
    val ctx = Context.discover().toOption.get
    val res = SysUtils.runScreenshot(ctx, List("invalid-mode"))
    assert(res.isLeft)
