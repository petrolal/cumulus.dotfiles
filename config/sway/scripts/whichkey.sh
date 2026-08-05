#!/usr/bin/env bash
# which-key style cheatsheet for Sway.
# Parses bindsym/bindcode/mode lines from the LIVE, resolved sway config —
# fetched from the running compositor via `swaymsg -t get_config`, so
# `include`d files (e.g. colors.conf) and variables are captured, not just
# the top-level config file. Falls back to reading the config file directly
# if swaymsg/jq aren't available (e.g. running outside a sway session).
# Read-only: selecting an entry just closes the popup.

set -euo pipefail

CONFIG="${SWAY_CONFIG:-$HOME/.config/sway/config}"

get_resolved_config() {
  if command -v swaymsg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 \
    && swaymsg -t get_version >/dev/null 2>&1; then
    swaymsg -t get_config | jq -r '.config'
    return
  fi
  cat "$CONFIG"
}

# Expand $var references (e.g. $mod, $left) using their `set $name value` definitions.
# Note: gawk/mawk gsub() takes an ERE, so the "$" in a variable name (e.g. "$mod")
# must be escaped or it's read as an end-of-line anchor and never matches.
get_resolved_config | awk '
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
' \
  | sort -u \
  | awk '{ key = $1; $1 = ""; sub(/^ /, ""); printf "%-22s → %s\n", key, $0 }' \
  | wofi --show dmenu --prompt "which-key" --width 700 --height 600 --lines 20 \
  > /dev/null
