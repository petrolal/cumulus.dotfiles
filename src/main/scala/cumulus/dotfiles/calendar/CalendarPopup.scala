package cumulus.dotfiles.calendar

import cumulus.dotfiles.context.Context
import cumulus.dotfiles.error.{CommandError, CumulusError}
import cumulus.dotfiles.theme.ThemeEngine

object CalendarPopup:
  def run(ctx: Context, args: List[String] = Nil): Either[CumulusError, Unit] =
    // Toggle behavior: if already running, kill it to close
    val myPid = ProcessHandle.current().pid()
    try
      val checkRes = os.proc("pgrep", "-f", "cumulus-calendar-runner").call(check = false)
      if checkRes.exitCode == 0 then
        val pids = checkRes.out.text().trim.split("\\s+").filter(_.nonEmpty).map(_.toLong).filter(_ != myPid)
        if pids.nonEmpty then
          for pid <- pids do
            try os.proc("kill", pid.toString).call(check = false) catch case _: Exception => ()
          return Right(())
    catch
      case _: Exception => ()

    // Ensure helper script is deployed in ~/.local/share/cumulus/
    val runnerScript = ctx.shareDir / "cumulus-calendar-runner.py"
    os.makeDir.all(ctx.shareDir)
    os.write.over(runnerScript, PythonRunnerScript)
    try os.proc("chmod", "+x", runnerScript.toString).call(check = false) catch case _: Exception => ()

    val palette = ThemeEngine.getActivePalette(ctx)
    val waybarTheme = ctx.configDir / "waybar" / "theme.css"
    val themePath = if os.exists(waybarTheme) then waybarTheme.toString else ""

    try
      os.proc(
        "python3", runnerScript.toString,
        "--base", palette.base,
        "--accent", palette.accent,
        "--text", palette.text,
        "--mantle", palette.mantle,
        "--red", palette.red,
        "--theme-file", themePath
      ).spawn()
      Right(())
    catch
      case e: Exception => Left(CommandError(s"Calendar popup launch failed: ${e.getMessage}"))

  val PythonRunnerScript: String =
    """#!/usr/bin/env python3
      |import sys
      |import os
      |import signal
      |import datetime
      |import calendar
      |import argparse
      |import gi
      |
      |gi.require_version("Gtk", "3.0")
      |gi.require_version("GtkLayerShell", "0.1")
      |from gi.repository import Gtk, Gdk, GtkLayerShell, GLib
      |
      |class CustomCalendar(Gtk.Box):
      |    def __init__(self, theme_colors):
      |        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=8)
      |        self.theme_colors = theme_colors
      |        self.now = datetime.datetime.now()
      |        self.view_year = self.now.year
      |        self.view_month = self.now.month
      |        self.selected_date = (self.now.year, self.now.month, self.now.day)
      |        
      |        # Month navigation header
      |        nav_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
      |        nav_box.set_name("cal-nav")
      |        
      |        self.prev_btn = Gtk.Button(label="‹")
      |        self.prev_btn.set_name("nav-btn")
      |        self.prev_btn.connect("clicked", self.prev_month)
      |        nav_box.pack_start(self.prev_btn, False, False, 0)
      |        
      |        self.month_label = Gtk.Label()
      |        self.month_label.set_name("month-header-label")
      |        self.month_label.set_xalign(0.5)
      |        nav_box.pack_start(self.month_label, True, True, 0)
      |        
      |        self.next_btn = Gtk.Button(label="›")
      |        self.next_btn.set_name("nav-btn")
      |        self.next_btn.connect("clicked", self.next_month)
      |        nav_box.pack_end(self.next_btn, False, False, 0)
      |        
      |        self.pack_start(nav_box, False, False, 0)
      |        
      |        # Calendar Grid
      |        self.grid = Gtk.Grid()
      |        self.grid.set_name("cal-grid")
      |        self.grid.set_column_homogeneous(True)
      |        self.grid.set_row_homogeneous(True)
      |        self.grid.set_column_spacing(4)
      |        self.grid.set_row_spacing(4)
      |        self.pack_start(self.grid, True, True, 0)
      |        
      |        self.render_calendar()
      |
      |    def prev_month(self, btn):
      |        if self.view_month == 1:
      |            self.view_month = 12
      |            self.view_year -= 1
      |        else:
      |            self.view_month -= 1
      |        self.render_calendar()
      |
      |    def next_month(self, btn):
      |        if self.view_month == 12:
      |            self.view_month = 1
      |            self.view_year += 1
      |        else:
      |            self.view_month += 1
      |        self.render_calendar()
      |
      |    def render_calendar(self):
      |        for child in self.grid.get_children():
      |            self.grid.remove(child)
      |            
      |        month_name = datetime.date(self.view_year, self.view_month, 1).strftime("%B %Y")
      |        self.month_label.set_markup(f"<span font_weight='bold' size='115%'>{month_name}</span>")
      |        
      |        weekdays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
      |        for col, wd in enumerate(weekdays):
      |            lbl = Gtk.Label()
      |            lbl.set_markup(f"<span font_weight='bold' size='90%'>{wd}</span>")
      |            lbl.set_name("weekday-header")
      |            lbl.set_xalign(0.5)
      |            lbl.set_yalign(0.5)
      |            lbl.set_size_request(34, 26)
      |            self.grid.attach(lbl, col, 0, 1, 1)
      |            
      |        cal_matrix = calendar.monthcalendar(self.view_year, self.view_month)
      |        for row, week in enumerate(cal_matrix):
      |            for col, day in enumerate(week):
      |                if day == 0:
      |                    lbl = Gtk.Label(label="")
      |                    lbl.set_size_request(34, 30)
      |                    self.grid.attach(lbl, col, row + 1, 1, 1)
      |                else:
      |                    btn = Gtk.Button()
      |                    btn.set_relief(Gtk.ReliefStyle.NONE)
      |                    btn.set_size_request(34, 30)
      |                    
      |                    lbl = Gtk.Label()
      |                    lbl.set_text(str(day))
      |                    lbl.set_xalign(0.5)
      |                    lbl.set_yalign(0.5)
      |                    btn.add(lbl)
      |                    
      |                    is_today = (self.view_year == self.now.year and self.view_month == self.now.month and day == self.now.day)
      |                    is_selected = (self.view_year == self.selected_date[0] and self.view_month == self.selected_date[1] and day == self.selected_date[2])
      |                    
      |                    if is_selected:
      |                        btn.set_name("day-cube-selected")
      |                    elif is_today:
      |                        btn.set_name("day-cube-today")
      |                    else:
      |                        btn.set_name("day-cube")
      |                        
      |                    def on_day_click(b, y=self.view_year, m=self.view_month, d=day):
      |                        self.selected_date = (y, m, d)
      |                        self.render_calendar()
      |                        
      |                    btn.connect("clicked", on_day_click)
      |                    self.grid.attach(btn, col, row + 1, 1, 1)
      |                    
      |        self.grid.show_all()
      |
      |def main():
      |    parser = argparse.ArgumentParser()
      |    parser.add_argument("--base", default="#071521")
      |    parser.add_argument("--accent", default="#FF9900")
      |    parser.add_argument("--text", default="#E0E6ED")
      |    parser.add_argument("--mantle", default="#040D15")
      |    parser.add_argument("--red", default="#EF4444")
      |    parser.add_argument("--theme-file", default="")
      |    args = parser.parse_args()
      |
      |    base_color = args.base
      |    accent_color = args.accent
      |    text_color = args.text
      |    mantle_color = args.mantle
      |    red_color = args.red
      |
      |    if args.theme_file and os.path.exists(args.theme_file):
      |        try:
      |            with open(args.theme_file) as f:
      |                for line in f:
      |                    if "@define-color base" in line:
      |                        base_color = line.split()[-1].strip("; ")
      |                    elif "@define-color accent" in line:
      |                        accent_color = line.split()[-1].strip("; ")
      |                    elif "@define-color text" in line:
      |                        text_color = line.split()[-1].strip("; ")
      |                    elif "@define-color mantle" in line:
      |                        mantle_color = line.split()[-1].strip("; ")
      |                    elif "@define-color red" in line:
      |                        red_color = line.split()[-1].strip("; ")
      |        except Exception:
      |            pass
      |
      |    win = Gtk.Window()
      |    win.set_title("Cumulus Calendar")
      |    win.set_resizable(False)
      |    win.set_name("calendar-window")
      |
      |    GtkLayerShell.init_for_window(win)
      |    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.TOP)
      |    GtkLayerShell.set_namespace(win, "cumulus-calendar-popup")
      |    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.TOP, True)
      |    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.TOP, 6)
      |    GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.ON_DEMAND)
      |
      |    popup_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
      |    popup_card.set_name("calendar-card")
      |    win.add(popup_card)
      |
      |    now = datetime.datetime.now()
      |    header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
      |    
      |    header_label = Gtk.Label()
      |    header_label.set_markup(f"<span size='115%' font_weight='bold'>{now.strftime('%A, %d %B %Y')}</span>")
      |    header_label.set_name("calendar-header")
      |    header_label.set_xalign(0.0)
      |    header_box.pack_start(header_label, True, True, 0)
      |
      |    close_btn = Gtk.Button(label="✕")
      |    close_btn.set_name("calendar-close-btn")
      |    close_btn.set_relief(Gtk.ReliefStyle.NONE)
      |    close_btn.connect("clicked", lambda b: Gtk.main_quit())
      |    header_box.pack_end(close_btn, False, False, 0)
      |    popup_card.pack_start(header_box, False, False, 0)
      |
      |    custom_cal = CustomCalendar({"base": base_color, "accent": accent_color})
      |    popup_card.pack_start(custom_cal, True, True, 0)
      |
      |    def on_key_press(widget, event):
      |        if event.keyval == Gdk.KEY_Escape:
      |            Gtk.main_quit()
      |            return True
      |        return False
      |    win.connect("key-press-event", on_key_press)
      |
      |    def on_focus_out(widget, event):
      |        toplevel = win.get_toplevel()
      |        if not toplevel.has_toplevel_focus():
      |            GLib.timeout_add(150, lambda: Gtk.main_quit() if not win.has_toplevel_focus() else None)
      |        return False
      |    win.connect("focus-out-event", on_focus_out)
      |
      |    css_provider = Gtk.CssProvider()
      |    custom_css = f'''
      |    window#calendar-window {{
      |        background-color: transparent;
      |    }}
      |    #calendar-card {{
      |        background-color: {base_color};
      |        border: 2px solid {accent_color};
      |        border-radius: 8px;
      |        padding: 12px 14px;
      |        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.6);
      |    }}
      |    #calendar-header {{
      |        color: {accent_color};
      |        font-family: "JetBrainsMono Nerd Font", monospace;
      |        font-size: 13px;
      |        font-weight: bold;
      |    }}
      |    button,
      |    button:backdrop,
      |    button:focus,
      |    button:active {{
      |        background-image: none;
      |        box-shadow: none;
      |        outline: none;
      |    }}
      |    #calendar-close-btn,
      |    button#calendar-close-btn {{
      |        background: transparent;
      |        background-color: transparent;
      |        background-image: none;
      |        box-shadow: none;
      |        color: {text_color};
      |        font-size: 12px;
      |        font-weight: bold;
      |        padding: 2px 6px;
      |        border-radius: 4px;
      |        border: none;
      |    }}
      |    #calendar-close-btn:hover,
      |    button#calendar-close-btn:hover {{
      |        background: {red_color};
      |        background-color: {red_color};
      |        color: {base_color};
      |    }}
      |    #cal-nav {{
      |        background-color: {mantle_color};
      |        border: 1px solid {accent_color};
      |        border-radius: 6px;
      |        padding: 4px 6px;
      |    }}
      |    #month-header-label {{
      |        color: {accent_color};
      |        font-family: "JetBrainsMono Nerd Font", monospace;
      |        font-weight: bold;
      |    }}
      |    button#nav-btn,
      |    button#nav-btn:backdrop,
      |    button#nav-btn:focus,
      |    #nav-btn {{
      |        background: transparent;
      |        background-color: transparent;
      |        background-image: none;
      |        box-shadow: none;
      |        border: none;
      |        border-radius: 4px;
      |        padding: 0 8px;
      |    }}
      |    button#nav-btn label,
      |    #nav-btn label {{
      |        color: {accent_color};
      |        font-family: "JetBrainsMono Nerd Font", monospace;
      |        font-size: 16px;
      |        font-weight: bold;
      |    }}
      |    button#nav-btn:hover,
      |    #nav-btn:hover {{
      |        background: {accent_color};
      |        background-color: {accent_color};
      |        background-image: none;
      |        box-shadow: none;
      |    }}
      |    button#nav-btn:hover label,
      |    #nav-btn:hover label {{
      |        color: {base_color};
      |    }}
      |    #cal-grid {{
      |        background-color: {mantle_color};
      |        border: 1px solid {accent_color};
      |        border-radius: 6px;
      |        padding: 8px;
      |    }}
      |    #weekday-header {{
      |        color: {accent_color};
      |        font-family: "JetBrainsMono Nerd Font", monospace;
      |        font-weight: bold;
      |        font-size: 12px;
      |    }}
      |    #day-cube,
      |    #day-cube-today,
      |    #day-cube-selected,
      |    button#day-cube,
      |    button#day-cube-today,
      |    button#day-cube-selected {{
      |        background-image: none;
      |        box-shadow: none;
      |        border-radius: 6px;
      |        padding: 0;
      |        margin: 0;
      |        border: none;
      |        font-family: "JetBrainsMono Nerd Font", monospace;
      |        font-size: 13px;
      |    }}
      |    #day-cube,
      |    button#day-cube {{
      |        background: transparent;
      |        background-color: transparent;
      |        color: {text_color};
      |    }}
      |    #day-cube:hover,
      |    button#day-cube:hover {{
      |        background-color: rgba(255, 153, 0, 0.25);
      |        color: {accent_color};
      |    }}
      |    #day-cube-today,
      |    button#day-cube-today {{
      |        background: transparent;
      |        background-color: transparent;
      |        color: {accent_color};
      |        border: 1px solid {accent_color};
      |        font-weight: bold;
      |    }}
      |    #day-cube-today:hover,
      |    button#day-cube-today:hover {{
      |        background: {accent_color};
      |        background-color: {accent_color};
      |        color: {base_color};
      |    }}
      |    #day-cube-selected,
      |    button#day-cube-selected {{
      |        background: {accent_color};
      |        background-color: {accent_color};
      |        color: {base_color};
      |        font-weight: bold;
      |    }}
      |    #day-cube-selected label,
      |    button#day-cube-selected label {{
      |        color: {base_color};
      |        font-weight: bold;
      |    }}
      |    '''
      |    css_provider.load_from_data(custom_css.encode("utf-8"))
      |    Gtk.StyleContext.add_provider_for_screen(
      |        Gdk.Screen.get_default(),
      |        css_provider,
      |        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
      |    )
      |
      |    win.show_all()
      |    Gtk.main()
      |
      |if __name__ == "__main__":
      |    main()
      |""".stripMargin
