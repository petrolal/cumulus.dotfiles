#!/usr/bin/env python3
import sys
import os
import signal
import datetime
import gi

gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, Gdk, GtkLayerShell, GLib

def is_already_running():
    # If already open, close it (toggle behavior)
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

def main():
    if is_already_running():
        sys.exit(0)

    # Load active theme colors
    theme_css_path = os.path.expanduser("~/.config/waybar/theme.css")
    base_color = "#071521"
    accent_color = "#FF9900"
    text_color = "#E0E6ED"
    mantle_color = "#040D15"
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
    popup_card.set_margin_top(0)
    popup_card.set_margin_bottom(0)
    popup_card.set_margin_start(0)
    popup_card.set_margin_end(0)
    win.add(popup_card)

    # Header with formatted date
    now = datetime.datetime.now()
    header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
    
    header_label = Gtk.Label()
    header_label.set_markup(f"<span size='120%' font_weight='bold'>{now.strftime('%A, %d %B %Y')}</span>")
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

    # GTK Calendar widget with clean symmetrical 7-column layout
    cal = Gtk.Calendar()
    cal.set_property("show-heading", True)
    cal.set_property("show-day-names", True)
    cal.set_property("show-week-numbers", False)
    cal.set_property("show-details", False)
    cal.set_name("calendar-widget")
    popup_card.pack_start(cal, True, True, 0)

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
        padding: 12px;
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.6);
    }}
    #calendar-header {{
        color: {accent_color};
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 14px;
        font-weight: bold;
        padding-left: 4px;
    }}
    #calendar-close-btn {{
        background-color: transparent;
        color: {text_color};
        font-size: 13px;
        font-weight: bold;
        padding: 2px 6px;
        border-radius: 4px;
        border: none;
    }}
    #calendar-close-btn:hover {{
        background-color: {red_color};
        color: {base_color};
    }}
    calendar {{
        background-color: {mantle_color};
        color: {text_color};
        border: 1px solid {accent_color};
        border-radius: 6px;
        padding: 8px;
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 14px;
    }}
    calendar:selected {{
        background-color: {accent_color};
        color: {base_color};
        font-weight: bold;
        border-radius: 4px;
    }}
    calendar.header {{
        color: {accent_color};
        font-weight: bold;
        font-size: 14px;
        padding-bottom: 6px;
    }}
    calendar.button {{
        color: {text_color};
        padding: 2px 6px;
        border-radius: 4px;
    }}
    calendar.button:hover {{
        background-color: {accent_color};
        color: {base_color};
    }}
    calendar:indeterminate {{
        color: rgba(224, 230, 237, 0.35);
    }}
    calendar.highlight {{
        color: {accent_color};
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
