package cumulus

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.theme.{Palette, ThemeEngine}
import munit.FunSuite

class ThemeSuite extends FunSuite:
  test("Palette.find retrieves default and named palettes"):
    val nord = Palette.find("nord")
    assertEquals(nord.name, "nord")
    assertEquals(nord.base, "#2e3440")

    val mocha = Palette.find("unknown-theme")
    assertEquals(mocha.name, "catppuccin-mocha")

  test("ThemeEngine.run renders theme config files"):
    val ctx = Context.discover().toOption.get
    val res = ThemeEngine.run(ctx, List("catppuccin-mocha"))
    assert(res.isRight)
    assert(os.exists(ctx.configDir / "kitty" / "theme.conf"))
    assert(os.exists(ctx.configDir / "waybar" / "theme.css"))
    assert(os.exists(ctx.configDir / "wofi" / "theme.css"))
