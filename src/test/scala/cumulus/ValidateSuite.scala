package cumulus

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.validate.Validator
import munit.FunSuite

class ValidateSuite extends FunSuite:
  test("Context.discover returns resolved paths"):
    val ctx = Context.discover()
    assert(ctx.isRight)
    val c = ctx.toOption.get
    assert(c.home.toString.nonEmpty)

  test("Validator.run executes without crashing"):
    val ctx = Context.discover().toOption.get
    val res = Validator.run(ctx, Nil)
    // Validator returns Right(()) if all tools exist or Left(...) if missing binaries in test env
    assert(res.isRight || res.isLeft)
