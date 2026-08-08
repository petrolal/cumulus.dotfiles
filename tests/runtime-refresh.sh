#!/usr/bin/env bash
#
# Integration tests for scripts/runtime-refresh.sh using local command stubs.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'kill "$KITTY_SERVER" "$NVIM_SERVER" 2>/dev/null || true; rm -rf "$TMP_DIR"' EXIT

assert() {
  if ! "$@"; then
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
  fi
}

mkdir -p "$TMP_DIR/bin" "$TMP_DIR/home/.config/cumulus/theme" \
  "$TMP_DIR/runtime/nvim"
cat > "$TMP_DIR/home/.config/cumulus/theme/state" <<'EOF'
FLAVOR=mocha
MODE=flat
WALLPAPER=
WALLPAPER_SOURCE=flat
INTERVAL=30m
NVIM_COLORSCHEME=catppuccin-mocha
EOF
printf '#!/usr/bin/env bash\nif [[ \"$*\" == *get_version* ]]; then printf \"sway-check\\\\n\" >> \"$REFRESH_LOG\"; else printf \"sway\\\\n\" >> \"$REFRESH_LOG\"; fi\n' > "$TMP_DIR/bin/swaymsg"
printf '#!/usr/bin/env bash\nif [[ \"$*\" == *waybar* ]]; then exit 0; fi\nexit 0\n' > "$TMP_DIR/bin/pgrep"
printf '#!/usr/bin/env bash\nif [[ \"$*\" == *waybar* ]]; then printf \"waybar\\\\n\" >> \"$REFRESH_LOG\"; else printf \"wofi\\\\n\" >> \"$REFRESH_LOG\"; fi\n' > "$TMP_DIR/bin/pkill"
printf '#!/usr/bin/env bash\nif [ \"${FAIL_KITTY:-false}\" = true ]; then exit 1; fi\nprintf \"kitty\\\\n\" >> \"$REFRESH_LOG\"\n' > "$TMP_DIR/bin/kitty"
printf '#!/usr/bin/env bash\nprintf \"neovim\\\\n\" >> \"$REFRESH_LOG\"\n' > "$TMP_DIR/bin/nvim"
printf '#!/usr/bin/env bash\nif [ \"$1\" = writable ]; then exit 0; fi\nprintf \"os\\\\n\" >> \"$REFRESH_LOG\"\n' > "$TMP_DIR/bin/gsettings"
printf '#!/usr/bin/env bash\nprintf \"rgb\\\\n\" >> \"$REFRESH_LOG\"\n' > "$TMP_DIR/bin/openrgb"
chmod +x "$TMP_DIR/bin/"*

python3 - "$TMP_DIR/runtime/cumulus-kitty" <<'PY' &
import socket, sys
s = socket.socket(socket.AF_UNIX)
s.bind(sys.argv[1])
s.listen(1)
try:
    while True:
        s.accept()[0].close()
except KeyboardInterrupt:
    pass
PY
KITTY_SERVER=$!
python3 - "$TMP_DIR/runtime/nvim/test.sock" <<'PY' &
import socket, sys
s = socket.socket(socket.AF_UNIX)
s.bind(sys.argv[1])
s.listen(1)
try:
    while True:
        s.accept()[0].close()
except KeyboardInterrupt:
    pass
PY
NVIM_SERVER=$!

for socket in "$TMP_DIR/runtime/cumulus-kitty" "$TMP_DIR/runtime/nvim/test.sock"; do
  for attempt in {1..50}; do
    [ -S "$socket" ] && break
    sleep 0.01
  done
  assert test -S "$socket"
done

export HOME="$TMP_DIR/home"
export XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export REFRESH_LOG="$TMP_DIR/refresh.log"
export PATH="$TMP_DIR/bin:/usr/bin:/bin"

"$REPO_ROOT/scripts/runtime-refresh.sh" > "$TMP_DIR/complete.log"
assert rg -q 'Refresh result: complete \(7 adapters refreshed\)' "$TMP_DIR/complete.log"
assert test "$(wc -l < "$HOME/.config/cumulus/theme/state")" -eq 6
assert rg -q '^FLAVOR=mocha$' "$HOME/.config/cumulus/theme/state"
assert rg -q '^NVIM_COLORSCHEME=catppuccin-mocha$' "$HOME/.config/cumulus/theme/state"
expected=(sway waybar kitty wofi neovim os rgb)
previous=0
for adapter in "${expected[@]}"; do
  line="$(rg -n "^$adapter$" "$REFRESH_LOG" | cut -d: -f1)"
  assert test "$line" -gt "$previous"
  previous="$line"
done

: > "$REFRESH_LOG"
FAIL_KITTY=true "$REPO_ROOT/scripts/runtime-refresh.sh" > "$TMP_DIR/partial.log"
assert rg -q 'Refresh result: partial \(6 refreshed, 1 deferred\)' "$TMP_DIR/partial.log"
assert rg -q 'kitty: deferred or unavailable' "$TMP_DIR/partial.log"
assert rg -q '^wofi$' "$REFRESH_LOG"
assert rg -q '^neovim$' "$REFRESH_LOG"
assert rg -q '^os$' "$REFRESH_LOG"
assert rg -q '^rgb$' "$REFRESH_LOG"

printf 'PASS: runtime refresh tests\n'
