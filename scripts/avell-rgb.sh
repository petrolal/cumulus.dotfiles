#!/usr/bin/env bash
#
# avell-rgb.sh — control RGB backlight on Avell / Uniwill / Tongfang (UNIW0001 / 093A:0255) keyboards.
#
set -euo pipefail

HEX_COLOR="${1:-0073bb}"
HEX_COLOR="${HEX_COLOR#\#}"

UPDATED=false

# 1. Check Tuxedo / Tongfang Sysfs interface (/sys/devices/platform/tuxedo_keyboard/)
if [ -d "/sys/devices/platform/tuxedo_keyboard" ]; then
  COLOR_FORMAT="0x$HEX_COLOR"
  for sys_node in /sys/devices/platform/tuxedo_keyboard/color_*; do
    [ -w "$sys_node" ] || continue
    if echo "$COLOR_FORMAT" > "$sys_node" 2>/dev/null; then
      UPDATED=true
    fi
  done
  if $UPDATED; then
    exit 0
  fi
fi

# 2. Check LED sysfs backlight nodes
for sys_node in /sys/class/leds/*kbd_backlight*/color /sys/class/leds/*rgb*/color; do
  [ -w "$sys_node" ] || continue
  if echo "0x$HEX_COLOR" > "$sys_node" 2>/dev/null; then
    UPDATED=true
  fi
done
if $UPDATED; then
  exit 0
fi

# Convert hex to R G B integers
R=$((16#${HEX_COLOR:0:2}))
G=$((16#${HEX_COLOR:2:2}))
B=$((16#${HEX_COLOR:4:2}))

# 3. Find UNIW0001 / 093A:0255 hidraw device node
HIDRAW_NODE=""
for h in /sys/class/hidraw/*; do
  [ -d "$h" ] || continue
  name="$(cat "$h/device/uevent" 2>/dev/null | grep HID_NAME || true)"
  if [[ "$name" == *"UNIW"* ]] || [[ "$name" == *"093A:0255"* ]]; then
    HIDRAW_NODE="/dev/$(basename "$h")"
    break
  fi
done

if [ -n "$HIDRAW_NODE" ] && [ -w "$HIDRAW_NODE" ]; then
  if python3 - "$HIDRAW_NODE" "$R" "$G" "$B" <<'PY'
import sys, fcntl

def HIDIOCSFEATURE(length):
    return 0xC0004806 | (length << 16)

node = sys.argv[1]
r = int(sys.argv[2])
g = int(sys.argv[3])
b = int(sys.argv[4])

# Uniwill / Tongfang HID packets sequence
packets = [
    # Brightness max (0xCC 0x09 0x05)
    bytearray([0xCC, 0x09, 0x05] + [0]*61),
    # Mode static (0xCC 0x08 0x01)
    bytearray([0xCC, 0x08, 0x01] + [0]*61),
    # 4-Zone color (0xCC 0x01)
    bytearray([0xCC, 0x01, r, g, b, r, g, b, r, g, b, r, g, b, 0x00, 0x05] + [0]*48),
    # Single zone color (0xCC 0x02)
    bytearray([0xCC, 0x02, r, g, b, 0x05] + [0]*58),
    # ITE 8297 feature report (0x51 0x2C)
    bytearray([0x51, 0x2C, r, g, b, 0x00, 0x00] + [0]*57),
]

success = False
with open(node, 'r+b', buffering=0) as f:
    for p in packets:
        try:
            fcntl.ioctl(f, HIDIOCSFEATURE(len(p)), p)
            f.write(bytes(p))
            success = True
        except Exception:
            pass

if not success:
    sys.exit(1)
PY
  then
    UPDATED=true
  fi
fi

if $UPDATED; then
  exit 0
else
  exit 1
fi
