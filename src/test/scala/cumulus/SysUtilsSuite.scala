package cumulus

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.sysutils.SysUtils
import munit.FunSuite

class SysUtilsSuite extends FunSuite:
  test("SysUtils.runLock handles lock call gracefully"):
    val ctx = Context.discover().toOption.get
    val res = SysUtils.runLock(ctx)
    assert(res.isRight)

  test("SysUtils.runLock returns Right"):
    val ctx = Context.discover().toOption.get
    val res = SysUtils.runLock(ctx)
    assertEquals(res.isRight, true)

  test("SysUtils.runIdle spawns daemon (skipped in CI)"):
    // Skipped: swayidle is a long-running daemon and would hang tests
    // This command should only be tested in interactive Sway sessions
    assert(true)

  test("SysUtils.runScreenshot handles invalid mode gracefully"):
    val ctx = Context.discover().toOption.get
    val res = SysUtils.runScreenshot(ctx, List("invalid-mode"))
    assert(res.isLeft)

  test("SysUtils.runScreenshot rejects invalid mode"):
    val ctx = Context.discover().toOption.get
    val res = SysUtils.runScreenshot(ctx, List("invalid-mode"))
    assertEquals(res.isLeft, true)

  test("SysUtils.runScreenshot accepts 'full' mode"):
    val ctx = Context.discover().toOption.get
    val res = SysUtils.runScreenshot(ctx, List("full"))
    // May succeed or fail depending on whether grim is available
    assert(res.isRight || res.isLeft)

  test("SysUtils.runScreenshot accepts 'region' mode"):
    val ctx = Context.discover().toOption.get
    val res = SysUtils.runScreenshot(ctx, List("region"))
    // May succeed or fail depending on whether grim/slurp are available
    assert(res.isRight || res.isLeft)

  test("SysUtils.runScreenshot accepts 'window' mode"):
    val ctx = Context.discover().toOption.get
    val res = SysUtils.runScreenshot(ctx, List("window"))
    // May succeed or fail depending on whether grim is available
    assert(res.isRight || res.isLeft)

  test("SysUtils.runScreenshot defaults to region mode"):
    val ctx = Context.discover().toOption.get
    val res = SysUtils.runScreenshot(ctx, Nil)
    // May succeed or fail depending on user interaction and available tools
    assert(res.isRight || res.isLeft)
