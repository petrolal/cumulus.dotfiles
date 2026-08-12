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

  test("Palette.find case-insensitive lookup"):
    val ctx = Context.discover().toOption.get
    val aws1 = Palette.find("aws", ctx)
    val aws2 = Palette.find("AWS", ctx)
    val aws3 = Palette.find("Aws", ctx)
    assertEquals(aws1.name, aws2.name)
    assertEquals(aws2.name, aws3.name)

  test("Palette.FallbackPalette has valid colors"):
    val p = Palette.FallbackPalette
    assertEquals(p.name, "aws")
    assert(p.base.startsWith("#"))
    assert(p.accent.startsWith("#"))
    assert(p.text.startsWith("#"))

  test("ThemeEngine.run renders custom theme config files"):
    val ctx = Context.discover().toOption.get
    val res = ThemeEngine.run(ctx, List("aws"))
    assert(res.isRight)
    assert(os.exists(ctx.configDir / "kitty" / "theme.conf"))
    assert(os.exists(ctx.configDir / "waybar" / "theme.css"))
    assert(os.exists(ctx.configDir / "wofi" / "theme.css"))
    assert(os.exists(ctx.configDir / "wofi" / "style.css"))
    assert(os.exists(ctx.configDir / "rofi" / "theme.rasi"))

  test("ThemeEngine.run applies all supported themes"):
    val ctx = Context.discover().toOption.get
    for theme <- Seq("aws", "azure", "gcp", "oci") do
      val res = ThemeEngine.run(ctx, List(theme))
      assert(res.isRight, s"Theme $theme failed to apply")

  test("ThemeEngine.run with flat mode"):
    val ctx = Context.discover().toOption.get
    val res = ThemeEngine.run(ctx, List("aws", "--flat"))
    assert(res.isRight)

  test("ThemeEngine.run with rotate mode"):
    val ctx = Context.discover().toOption.get
    val res = ThemeEngine.run(ctx, List("aws", "--rotate"))
    assert(res.isRight)

  test("ThemeEngine.getActivePalette returns valid palette"):
    val ctx = Context.discover().toOption.get
    val p = ThemeEngine.getActivePalette(ctx)
    assert(p.name.nonEmpty)
    assert(p.base.nonEmpty)

  test("ThemeEngine renders sway colors.conf correctly"):
    val ctx = Context.discover().toOption.get
    ThemeEngine.run(ctx, List("aws"))
    val colorsFile = ctx.configDir / "sway" / "colors.conf"
    assert(os.exists(colorsFile))
    val content = os.read(colorsFile)
    assert(content.contains("client.focused"))

  test("ThemeEngine renders swaylock config"):
    val ctx = Context.discover().toOption.get
    ThemeEngine.run(ctx, List("aws"))
    val lockConfig = ctx.configDir / "swaylock" / "config"
    assert(os.exists(lockConfig))
    val content = os.read(lockConfig)
    assert(content.contains("font"))
