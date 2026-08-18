#!/usr/bin/env python3
import sys
import os
import signal
import datetime
import calendar
import gi

gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, Gdk, GtkLayerShell, GLib

def is_already_running():
    my_pid = os.getpid()
    try:
        import subprocess
        out = subprocess.check_output(["pgrep", "-f", "calendar-popup.py"]).decode().strip()
        pids = [int(p) for p in out.split() if int(p) != my_pid]
        if pids:
            for pid in pids:
                try:
                    os.kill(pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
            return True
    except Exception:
        pass
    return False

class CustomCalendar(Gtk.Box):
    def __init__(self, theme_colors):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        self.theme_colors = theme_colors
        self.now = datetime.datetime.now()
        self.view_year = self.now.year
        self.view_month = self.now.month
        self.selected_date = (self.now.year, self.now.month, self.now.day)
        
        # Month navigation header
        nav_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        nav_box.set_name("cal-nav")
        
        self.prev_btn = Gtk.Button(label="‹")
        self.prev_btn.set_name("nav-btn")
        self.prev_btn.connect("clicked", self.prev_month)
        nav_box.pack_start(self.prev_btn, False, False, 0)
        
        self.month_label = Gtk.Label()
        self.month_label.set_name("month-header-label")
        self.month_label.set_xalign(0.5)
        nav_box.pack_start(self.month_label, True, True, 0)
        
        self.next_btn = Gtk.Button(label="›")
        self.next_btn.set_name("nav-btn")
        self.next_btn.connect("clicked", self.next_month)
        nav_box.pack_end(self.next_btn, False, False, 0)
        
        self.pack_start(nav_box, False, False, 0)
        
        # Calendar Grid
        self.grid = Gtk.Grid()
        self.grid.set_name("cal-grid")
        self.grid.set_column_homogeneous(True)
        self.grid.set_row_homogeneous(True)
        self.grid.set_column_spacing(4)
        self.grid.set_row_spacing(4)
        self.pack_start(self.grid, True, True, 0)
        
        self.render_calendar()

    def prev_month(self, btn):
        if self.view_month == 1:
            self.view_month = 12
            self.view_year -= 1
        else:
            self.view_month -= 1
        self.render_calendar()

    def next_month(self, btn):
        if self.view_month == 12:
            self.view_month = 1
            self.view_year += 1
        else:
            self.view_month += 1
        self.render_calendar()

    def render_calendar(self):
        # Clear existing grid children
        for child in self.grid.get_children():
            self.grid.remove(child)
            
        month_name = datetime.date(self.view_year, self.view_month, 1).strftime("%B %Y")
        self.month_label.set_markup(f"<span font_weight='bold' size='115%'>{month_name}</span>")
        
        # Weekday headers (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
        weekdays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        for col, wd in enumerate(weekdays):
            lbl = Gtk.Label()
            lbl.set_markup(f"<span font_weight='bold' size='90%'>{wd}</span>")
            lbl.set_name("weekday-header")
            lbl.set_xalign(0.5)
            lbl.set_yalign(0.5)
            lbl.set_size_request(34, 26)
            self.grid.attach(lbl, col, 0, 1, 1)
            
        # Get month matrix (starting Monday)
        cal_matrix = calendar.monthcalendar(self.view_year, self.view_month)
        
        for row, week in enumerate(cal_matrix):
            for col, day in enumerate(week):
                if day == 0:
                    lbl = Gtk.Label(label="")
                    lbl.set_size_request(34, 30)
                    self.grid.attach(lbl, col, row + 1, 1, 1)
                else:
                    btn = Gtk.Button()
                    btn.set_relief(Gtk.ReliefStyle.NONE)
                    btn.set_size_request(34, 30)
                    
                    lbl = Gtk.Label()
                    lbl.set_text(str(day))
                    lbl.set_xalign(0.5)
                    lbl.set_yalign(0.5)
                    btn.add(lbl)
                    
                    is_today = (self.view_year == self.now.year and self.view_month == self.now.month and day == self.now.day)
                    is_selected = (self.view_year == self.selected_date[0] and self.view_month == self.selected_date[1] and day == self.selected_date[2])
                    
                    if is_selected:
                        btn.set_name("day-cube-selected")
                    elif is_today:
                        btn.set_name("day-cube-today")
                    else:
                        btn.set_name("day-cube")
                        
                    def on_day_click(b, y=self.view_year, m=self.view_month, d=day):
                        self.selected_date = (y, m, d)
                        self.render_calendar()
                        
                    btn.connect("clicked", on_day_click)
                    self.grid.attach(btn, col, row + 1, 1, 1)
                    
        self.grid.show_all()

def main():
    if is_already_running():
        sys.exit(0)

    # Load active theme colors
    theme_css_path = os.path.expanduser("~/.config/waybar/theme.css")
    base_color = "#071521"
    accent_color = "#FF9900"
    text_color = "#E0E6ED"
    mantle_color = "#040D15"
    subtext_color = "#8A99A8"
    red_color = "#EF4444"

    if os.path.exists(theme_css_path):
        try:
            with open(theme_css_path) as f:
                for line in f:
                    if "@define-color base" in line:
                        base_color = line.split()[-1].strip("; ")
                    elif "@define-color accent" in line:
                        accent_color = line.split()[-1].strip("; ")
                    elif "@define-color text" in line:
                        text_color = line.split()[-1].strip("; ")
                    elif "@define-color mantle" in line:
                        mantle_color = line.split()[-1].strip("; ")
                    elif "@define-color subtext0" in line:
                        subtext_color = line.split()[-1].strip("; ")
                    elif "@define-color red" in line:
                        red_color = line.split()[-1].strip("; ")
        except Exception:
            pass

    # Initialize GTK window
    win = Gtk.Window()
    win.set_title("Cumulus Calendar")
    win.set_resizable(False)
    win.set_name("calendar-window")

    # Layer Shell configuration
    GtkLayerShell.init_for_window(win)
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.TOP)
    GtkLayerShell.set_namespace(win, "cumulus-calendar-popup")
    
    # Anchor to TOP centered directly under the bar with matching 6px notification margin
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.TOP, True)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.TOP, 6)
    GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.ON_DEMAND)

    # Main popup card with identical margin, padding, border radius to notifications
    popup_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
    popup_card.set_name("calendar-card")
    win.add(popup_card)

    # Header with formatted date
    now = datetime.datetime.now()
    header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
    
    header_label = Gtk.Label()
    header_label.set_markup(f"<span size='115%' font_weight='bold'>{now.strftime('%A, %d %B %Y')}</span>")
    header_label.set_name("calendar-header")
    header_label.set_xalign(0.0)
    header_box.pack_start(header_label, True, True, 0)

    # Close button matching notification close-button
    close_btn = Gtk.Button(label="✕")
    close_btn.set_name("calendar-close-btn")
    close_btn.set_relief(Gtk.ReliefStyle.NONE)
    close_btn.connect("clicked", lambda b: Gtk.main_quit())
    header_box.pack_end(close_btn, False, False, 0)

    popup_card.pack_start(header_box, False, False, 0)

    # Custom Centered Grid Calendar
    custom_cal = CustomCalendar({"base": base_color, "accent": accent_color})
    popup_card.pack_start(custom_cal, True, True, 0)

    # Close on Escape key
    def on_key_press(widget, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()
            return True
        return False
    win.connect("key-press-event", on_key_press)

    # Dismiss when focus is lost to another application window
    def on_focus_out(widget, event):
        toplevel = win.get_toplevel()
        if not toplevel.has_toplevel_focus():
            GLib.timeout_add(150, lambda: Gtk.main_quit() if not win.has_toplevel_focus() else None)
        return False
    win.connect("focus-out-event", on_focus_out)

    # Load CSS styling matching notifications & control center exactly
    css_provider = Gtk.CssProvider()
    custom_css = f"""
    window#calendar-window {{
        background-color: transparent;
    }}
    #calendar-card {{
        background-color: {base_color};
        border: 2px solid {accent_color};
        border-radius: 8px;
        padding: 12px 14px;
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.6);
    }}
    #calendar-header {{
        color: {accent_color};
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 13px;
        font-weight: bold;
    }}
    #calendar-close-btn {{
        background-color: transparent;
        color: {text_color};
        font-size: 12px;
        font-weight: bold;
        padding: 2px 6px;
        border-radius: 4px;
        border: none;
    }}
    #calendar-close-btn:hover {{
        background-color: {red_color};
        color: {base_color};
    }}
    #cal-nav {{
        background-color: {mantle_color};
        border: 1px solid {accent_color};
        border-radius: 6px;
        padding: 4px 6px;
    }}
    #month-header-label {{
        color: {accent_color};
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-weight: bold;
    }}
    #nav-btn,
    #nav-btn label {{
        background-color: transparent;
        color: {accent_color};
        border: none;
        border-radius: 4px;
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 16px;
        font-weight: bold;
        padding: 0 8px;
    }}
    #nav-btn:hover,
    #nav-btn:hover label {{
        background-color: {accent_color};
        color: {base_color};
    }}
    #cal-grid {{
        background-color: {mantle_color};
        border: 1px solid {accent_color};
        border-radius: 6px;
        padding: 8px;
    }}
    #weekday-header {{
        color: {accent_color};
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-weight: bold;
        font-size: 12px;
    }}
    #day-cube,
    #day-cube-today,
    #day-cube-selected {{
        border-radius: 6px;
        padding: 0;
        margin: 0;
        border: none;
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 13px;
    }}
    #day-cube {{
        background-color: transparent;
        color: {text_color};
    }}
    #day-cube:hover {{
        background-color: rgba(255, 153, 0, 0.25);
        color: {accent_color};
    }}
    #day-cube-today {{
        background-color: transparent;
        color: {accent_color};
        border: 1px solid {accent_color};
        font-weight: bold;
    }}
    #day-cube-today:hover {{
        background-color: {accent_color};
        color: {base_color};
    }}
    #day-cube-selected {{
        background-color: {accent_color};
        color: {base_color};
        font-weight: bold;
    }}
    #day-cube-selected label {{
        color: {base_color};
        font-weight: bold;
    }}
    """
    css_provider.load_from_data(custom_css.encode("utf-8"))
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(),
        css_provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )

    win.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()
