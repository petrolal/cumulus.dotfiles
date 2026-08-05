#!/usr/bin/env bash
# which-key style cheatsheet for Sway.
# Parses bindsym/bindcode/mode lines from the live sway config (resolved via
# swaymsg so `include`d files and variables are captured too) and shows them
# in a searchable wofi popup. Read-only: selecting an entry just closes it.

set -euo pipefail

CONFIG="${SWAY_CONFIG:-$HOME/.config/sway/config}"

# Expand $var references (e.g. $mod, $left) using their `set $name value` definitions.
# Note: gawk/mawk gsub() takes an ERE, so the "$" in a variable name (e.g. "$mod")
# must be escaped or it's read as an end-of-line anchor and never matches.
awk '
  function ere_quote(s) {
    gsub(/[][\\.^$*+?(){}|]/, "\\\\&", s)
    return s
  }
  /^[ \t]*set[ \t]+\$[A-Za-z0-9_]+/ {
    name = $2
    $1 = ""; $2 = ""
    val = $0
    sub(/^[ \t]+/, "", val)
    gsub(/"/, "", val)
    vars[name] = val
    order[++n] = name
    next
  }
  /^[ \t]*(bindsym|bindcode)[ \t]+/ {
    line = $0
    sub(/^[ \t]*(bindsym|bindcode)[ \t]+/, "", line)
    for (i = 1; i <= n; i++) {
      v = order[i]
      gsub(ere_quote(v), vars[v], line)
    }
    print line
  }
' "$CONFIG" \
  | sort -u \
  | awk '{ key = $1; $1 = ""; sub(/^ /, ""); printf "%-22s → %s\n", key, $0 }' \
  | wofi --show dmenu --prompt "which-key" --width 700 --height 600 --lines 20 \
  > /dev/null
