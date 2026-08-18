#!/usr/bin/env python3
import sys
import os
import signal
import datetime
import cairo
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

def hex_to_rgb(h):
    h = h.strip("#")
    if len(h) == 3:
        h = "".join(2 * c for c in h)
    return tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))

class BubblePointer(Gtk.DrawingArea):
    def __init__(self, bg_color, border_color):
        super().__init__()
        self.bg_color = bg_color
        self.border_color = border_color
        self.set_size_request(26, 12)
        self.connect("draw", self.on_draw)

    def on_draw(self, widget, cr):
        br, bg, bb = hex_to_rgb(self.border_color)
        fr, fg, fb = hex_to_rgb(self.bg_color)
        
        w = float(widget.get_allocated_width())
        h = float(widget.get_allocated_height())
        
        # Center the triangle caret
        cx = w / 2.0
        hw = 12.0 # half-width of the triangle base
        
        # 1. Fill the triangle
        cr.move_to(cx - hw, h + 2.0)
        cr.line_to(cx, 2.0)
        cr.line_to(cx + hw, h + 2.0)
        cr.close_path()
        cr.set_source_rgb(fr, fg, fb)
        cr.fill()
        
        # 2. Stroke ONLY the two diagonal edges (no bottom dividing line)
        cr.set_line_width(2.0)
        cr.set_line_cap(cairo.LINE_CAP_ROUND)
        cr.set_line_join(cairo.LINE_JOIN_ROUND)
        cr.move_to(cx - hw, h + 2.0)
        cr.line_to(cx, 2.0)
        cr.line_to(cx + hw, h + 2.0)
        cr.set_source_rgb(br, bg, bb)
        cr.stroke()
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
    subtext_color = "#8A99A8"

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
    
    # Anchor to TOP centered directly under the clock
    GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.TOP, True)
    GtkLayerShell.set_margin(win, GtkLayerShell.Edge.TOP, 4)
    GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.ON_DEMAND)

    # Outer transparent layout
    outer_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
    outer_box.set_name("bubble-outer")
    win.add(outer_box)

    # Top pointed arrow aligned center (pointing directly at the clock)
    caret_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
    caret_box.set_halign(Gtk.Align.CENTER)
    pointer = BubblePointer(base_color, accent_color)
    caret_box.pack_start(pointer, False, False, 0)
    outer_box.pack_start(caret_box, False, False, 0)

    # Main bubble card container
    bubble_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
    bubble_card.set_name("calendar-bubble")
    bubble_card.set_margin_top(-2)
    outer_box.pack_start(bubble_card, True, True, 0)

    # Content box with padding
    content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
    content_box.set_margin_top(12)
    content_box.set_margin_bottom(16)
    content_box.set_margin_start(18)
    content_box.set_margin_end(18)
    bubble_card.pack_start(content_box, True, True, 0)

    # Header with formatted date
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

    # Dismiss when focus is lost to another application window
    def on_focus_out(widget, event):
        toplevel = win.get_toplevel()
        if not toplevel.has_toplevel_focus():
            GLib.timeout_add(150, lambda: Gtk.main_quit() if not win.has_toplevel_focus() else None)
        return False
    win.connect("focus-out-event", on_focus_out)

    # Load CSS styling
    css_provider = Gtk.CssProvider()
    custom_css = f"""
    window#calendar-window {{
        background-color: transparent;
    }}
    #bubble-outer {{
        background-color: transparent;
    }}
    #calendar-bubble {{
        background-color: {base_color};
        border: 2px solid {accent_color};
        border-radius: 16px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.75);
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
        border-radius: 10px;
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
