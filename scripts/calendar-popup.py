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

    # Initialize GTK window
    win = Gtk.Window()
    win.set_title("Cumulus Calendar")
    win.set_resizable(False)
    win.set_name("calendar-window")

    # Layer Shell configuration
    GtkLayerShell.init_for_window(win)
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.TOP)
    GtkLayerShell.set_namespace(win, "cumulus-calendar-popup")
    
    # Anchor to TOP and flush right below the 32px Waybar
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.TOP, True)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.TOP, 32)
    GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.ON_DEMAND)

    # Main solid background wrapper
    main_container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
    main_container.set_name("calendar-popup")
    main_container.set_margin_top(0)
    main_container.set_margin_bottom(0)
    main_container.set_margin_start(0)
    main_container.set_margin_end(0)
    win.add(main_container)

    # Content box with padding
    content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
    content_box.set_margin_top(14)
    content_box.set_margin_bottom(16)
    content_box.set_margin_start(18)
    content_box.set_margin_end(18)
    main_container.pack_start(content_box, True, True, 0)

    # Header with current time / date overview
    now = datetime.datetime.now()
    header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
    
    header_label = Gtk.Label()
    header_label.set_markup(f"<span size='125%' font_weight='bold'>{now.strftime('%A, %d %B %Y')}</span>")
    header_label.set_name("calendar-header")
    header_label.set_xalign(0.0)
    header_box.pack_start(header_label, True, True, 0)

    # Close button
    close_btn = Gtk.Button(label="✕")
    close_btn.set_name("calendar-close-btn")
    close_btn.set_relief(Gtk.ReliefStyle.NONE)
    close_btn.connect("clicked", lambda b: Gtk.main_quit())
    header_box.pack_end(close_btn, False, False, 0)

    content_box.pack_start(header_box, False, False, 0)

    # GTK Calendar widget
    cal = Gtk.Calendar()
    cal.set_property("show-heading", True)
    cal.set_property("show-day-names", True)
    cal.set_property("show-week-numbers", True)
    cal.set_property("show-details", True)
    cal.set_name("calendar-widget")
    content_box.pack_start(cal, True, True, 0)

    # Close on Escape key
    def on_key_press(widget, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()
            return True
        return False
    win.connect("key-press-event", on_key_press)

    # Dismiss when pointer leaves the window bounds and clicks outside
    def on_leave(widget, event):
        # Allow user to interact freely within the window
        pass
    win.connect("leave-notify-event", on_leave)

    # Dismiss when focus is lost to another application window
    def on_focus_out(widget, event):
        # If focus moves entirely outside of this layer-surface window
        toplevel = win.get_toplevel()
        if not toplevel.has_toplevel_focus():
            GLib.timeout_add(150, lambda: Gtk.main_quit() if not win.has_toplevel_focus() else None)
        return False
    win.connect("focus-out-event", on_focus_out)

    # Load CSS styling matching active desktop theme
    css_provider = Gtk.CssProvider()
    theme_css_path = os.path.expanduser("~/.config/waybar/theme.css")
    base_color = "#071521"
    accent_color = "#FF9900"
    text_color = "#E0E6ED"
    mantle_color = "#040D15"
    crust_color = "#02070B"

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
                    elif "@define-color crust" in line:
                        crust_color = line.split()[-1].strip("; ")
        except Exception:
            pass

    custom_css = f"""
    window#calendar-window {{
        background-color: transparent;
    }}
    #calendar-popup {{
        background-color: {base_color};
        border-left: 2px solid {accent_color};
        border-right: 2px solid {accent_color};
        border-bottom: 2px solid {accent_color};
        border-top: none;
        border-radius: 0 0 14px 14px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.7);
    }}
    #calendar-header {{
        color: {accent_color};
        font-family: "JetBrainsMono Nerd Font", sans-serif;
        font-size: 15px;
        font-weight: bold;
    }}
    #calendar-close-btn {{
        color: {text_color};
        font-size: 14px;
        font-weight: bold;
        padding: 2px 8px;
        border-radius: 6px;
        background-color: transparent;
        border: none;
    }}
    #calendar-close-btn:hover {{
        background-color: {accent_color};
        color: {base_color};
    }}
    calendar {{
        background-color: {mantle_color};
        color: {text_color};
        border: 1px solid {accent_color};
        border-radius: 8px;
        padding: 12px;
        font-family: "JetBrainsMono Nerd Font", sans-serif;
        font-size: 15px;
    }}
    calendar:selected {{
        background-color: {accent_color};
        color: {base_color};
        font-weight: bold;
        border-radius: 6px;
    }}
    calendar.header {{
        color: {accent_color};
        font-weight: bold;
        font-size: 16px;
        padding-bottom: 8px;
    }}
    calendar.button {{
        color: {text_color};
        padding: 4px 8px;
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
