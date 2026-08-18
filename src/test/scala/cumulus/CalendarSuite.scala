package cumulus

import cumulus.dotfiles.calendar.CalendarPopup
import cumulus.dotfiles.context.Context
import munit.FunSuite

class CalendarSuite extends FunSuite:
  test("CalendarPopup.run succeeds in discovering context and preparing runner"):
    val ctx = Context.discover().toOption.get
    assert(CalendarPopup.PythonRunnerScript.nonEmpty)
    assert(CalendarPopup.PythonRunnerScript.contains("GtkLayerShell"))
    assert(CalendarPopup.PythonRunnerScript.contains("CustomCalendar"))

  test("CalendarPopup extracts theme color tokens"):
    val ctx = Context.discover().toOption.get
    val palette = cumulus.dotfiles.theme.ThemeEngine.getActivePalette(ctx)
    assert(palette.name.nonEmpty)
    assert(palette.base.startsWith("#"))
    assert(palette.accent.startsWith("#"))
