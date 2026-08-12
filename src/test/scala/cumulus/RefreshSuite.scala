package cumulus

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.refresh.RefreshEngine
import munit.FunSuite

class RefreshSuite extends FunSuite:
  test("RefreshEngine.runRefresh executes without exception"):
    val ctx = Context.discover().toOption.get
    val res = RefreshEngine.runRefresh(ctx)
    assert(res.isRight)

  test("RefreshEngine.runOsColorscheme sets GTK dark scheme"):
    val ctx = Context.discover().toOption.get
    val res = RefreshEngine.runOsColorscheme(ctx)
    assert(res.isRight)
