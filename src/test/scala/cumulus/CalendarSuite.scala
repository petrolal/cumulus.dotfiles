package cumulus

import cumulus.dotfiles.calendar.CalendarPopup
import cumulus.dotfiles.context.Context
import java.time.LocalDate
import munit.FunSuite

class CalendarSuite extends FunSuite:
  test("CalendarPopup.generateCalendarLines generates valid month matrix"):
    val date = LocalDate.of(2026, 8, 18)
    val lines = CalendarPopup.generateCalendarLines(date)
    assert(lines.nonEmpty)
    assert(lines.exists(_.contains("August 2026")))
    assert(lines.exists(_.contains("Mo  Tu  We  Th  Fr  Sa  Su")))
    assert(lines.exists(_.contains("[18]"))) // highlighted today

  test("CalendarPopup extracts active theme palette correctly"):
    val ctx = Context.discover().toOption.get
    val palette = cumulus.dotfiles.theme.ThemeEngine.getActivePalette(ctx)
    assert(palette.name.nonEmpty)
    assert(palette.base.startsWith("#"))
    assert(palette.accent.startsWith("#"))
