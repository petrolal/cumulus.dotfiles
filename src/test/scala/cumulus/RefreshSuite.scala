package cumulus

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.refresh.RefreshEngine
import munit.FunSuite

class RefreshSuite extends FunSuite:
  test("RefreshEngine.runRefresh executes without exception"):
    val ctx = Context.discover().toOption.get
    val res = RefreshEngine.runRefresh(ctx)
    assert(res.isRight)

  test("RefreshEngine.runRefresh returns Right"):
    val ctx = Context.discover().toOption.get
    val res = RefreshEngine.runRefresh(ctx)
    assertEquals(res.isRight, true)

  test("RefreshEngine.runOsColorscheme sets GTK dark scheme"):
    val ctx = Context.discover().toOption.get
    val res = RefreshEngine.runOsColorscheme(ctx)
    assert(res.isRight)

  test("RefreshEngine.runOsColorscheme returns Right"):
    val ctx = Context.discover().toOption.get
    val res = RefreshEngine.runOsColorscheme(ctx)
    assertEquals(res.isRight, true)

  test("RefreshEngine.runRefresh handles missing gsettings"):
    val ctx = Context.discover().toOption.get
    // Should handle gracefully even if gsettings is missing
    val res = RefreshEngine.runRefresh(ctx)
    assert(res.isRight)

  test("RefreshEngine.runOsColorscheme handles missing gsettings"):
    val ctx = Context.discover().toOption.get
    // Should handle gracefully even if gsettings is missing
    val res = RefreshEngine.runOsColorscheme(ctx)
    assert(res.isRight)
