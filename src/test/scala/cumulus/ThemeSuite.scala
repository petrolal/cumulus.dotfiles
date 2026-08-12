package cumulus

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.theme.{Palette, ThemeEngine}
import munit.FunSuite

class ThemeSuite extends FunSuite:
  test("Palette.find retrieves custom palettes"):
    val ctx = Context.discover().toOption.get
    val aws = Palette.find("aws", ctx)
    assertEquals(aws.name, "aws")

    val fallback = Palette.find("unknown-theme", ctx)
    assert(fallback.name.nonEmpty)

  test("Palette.listAll discovers custom conf palettes"):
    val ctx = Context.discover().toOption.get
    val themes = Palette.listAll(ctx)
    assert(themes.contains("aws"))
    assert(themes.contains("azure"))
    assert(themes.contains("gcp"))
    assert(themes.contains("oci"))

  test("ThemeEngine.run renders custom theme config files"):
    val ctx = Context.discover().toOption.get
    val res = ThemeEngine.run(ctx, List("aws"))
    assert(res.isRight)
    assert(os.exists(ctx.configDir / "kitty" / "theme.conf"))
    assert(os.exists(ctx.configDir / "waybar" / "theme.css"))
    assert(os.exists(ctx.configDir / "wofi" / "theme.css"))
    assert(os.exists(ctx.configDir / "wofi" / "style.css"))
    assert(os.exists(ctx.configDir / "rofi" / "theme.rasi"))
