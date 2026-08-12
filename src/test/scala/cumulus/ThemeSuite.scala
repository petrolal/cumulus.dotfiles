package cumulus

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.theme.{Palette, ThemeEngine}
import munit.FunSuite

class ThemeSuite extends FunSuite:
  test("Palette.find retrieves default and named palettes"):
    val ctx = Context.discover().toOption.get
    val nord = Palette.find("nord", ctx)
    assertEquals(nord.name, "nord")
    assertEquals(nord.base, "#2e3440")

    val mocha = Palette.find("unknown-theme", ctx)
    assertEquals(mocha.name, "catppuccin-mocha")

  test("Palette.listAll discovers custom conf palettes"):
    val ctx = Context.discover().toOption.get
    val themes = Palette.listAll(ctx)
    assert(themes.contains("aws"))
    assert(themes.contains("azure"))
    assert(themes.contains("gcp"))
    assert(themes.contains("oci"))

  test("ThemeEngine.run renders theme config files"):
    val ctx = Context.discover().toOption.get
    val res = ThemeEngine.run(ctx, List("catppuccin-mocha"))
    assert(res.isRight)
    assert(os.exists(ctx.configDir / "kitty" / "theme.conf"))
    assert(os.exists(ctx.configDir / "waybar" / "theme.css"))
    assert(os.exists(ctx.configDir / "wofi" / "theme.css"))
