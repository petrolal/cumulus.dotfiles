#!/usr/bin/env python3
import sys
import os
import signal
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

    # Initialize GTK window
    win = Gtk.Window()
    win.set_title("Cumulus Calendar")
    win.set_resizable(False)
    win.set_app_paintable(True)
    win.set_name("calendar-popup")

    # Layer Shell configuration
    GtkLayerShell.init_for_window(win)
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.TOP)
    GtkLayerShell.set_namespace(win, "cumulus-calendar-popup")
    
    # Anchor to TOP and centered beneath the top bar
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.TOP, True)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.TOP, 40) # just below the 32px Waybar
    
    # Keyboard mode to intercept Escape and clicks outside
    GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.EXCLUSIVE)

    # Container box
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
    box.set_margin_top(12)
    box.set_margin_bottom(12)
    box.set_margin_start(16)
    box.set_margin_end(16)
    win.add(box)

    # Header with current time / date overview
    import datetime
    now = datetime.datetime.now()
    header_label = Gtk.Label()
    header_label.set_markup(f"<span size='130%' font_weight='bold'>{now.strftime('%A, %B %d, %Y')}</span>")
    header_label.set_name("calendar-header")
    box.pack_start(header_label, False, False, 4)

    # GTK Calendar widget
    cal = Gtk.Calendar()
    cal.set_property("show-heading", True)
    cal.set_property("show-day-names", True)
    cal.set_property("show-week-numbers", True)
    cal.set_name("calendar-widget")
    box.pack_start(cal, True, True, 4)

    # Close on focus-out / click outside / blur once focus is acquired
    import time
    start_time = time.time()

    def on_focus_out(widget, event):
        # Ignore spurious events in the first 250ms of window presentation
        if time.time() - start_time > 0.25:
            Gtk.main_quit()
        return False
    win.connect("focus-out-event", on_focus_out)

    # Close on Escape key
    def on_key_press(widget, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()
            return True
        return False
    win.connect("key-press-event", on_key_press)

    # Load CSS styling matching active desktop theme
    css_provider = Gtk.CssProvider()
    theme_css_path = os.path.expanduser("~/.config/waybar/theme.css")
    base_color = "#071521"
    accent_color = "#FF9900"
    text_color = "#E0E6ED"
    mantle_color = "#040D15"

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
        except Exception:
            pass

    custom_css = f"""
    window#calendar-popup {{
        background-color: {base_color};
        border: 2px solid {accent_color};
        border-radius: 10px;
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.6);
    }}
    #calendar-header {{
        color: {accent_color};
        padding: 4px 8px;
    }}
    calendar {{
        background-color: {mantle_color};
        color: {text_color};
        border: 1px solid {accent_color};
        border-radius: 8px;
        padding: 10px;
        font-family: "JetBrainsMono Nerd Font", sans-serif;
        font-size: 15px;
    }}
    calendar:selected {{
        background-color: {accent_color};
        color: {base_color};
        border-radius: 6px;
    }}
    calendar.header {{
        color: {accent_color};
        font-weight: bold;
        font-size: 16px;
    }}
    calendar.button {{
        color: {text_color};
    }}
    calendar.button:hover {{
        background-color: {accent_color};
        color: {base_color};
    }}
    calendar:indeterminate {{
        color: rgba(224, 230, 237, 0.4);
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
