# ── Environment ──
export EDITOR=nvim
export VISUAL=nvim
export PATH="$HOME/.local/bin:$PATH"

# Homebrew environment
if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -d "$HOME/.linuxbrew/bin" ]; then
  eval "$($HOME/.linuxbrew/bin/brew shellenv)"
elif [ -d "/opt/homebrew/bin" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Coursier bin PATH
[ -d "$HOME/.local/share/coursier/bin" ] && export PATH="$HOME/.local/share/coursier/bin:$PATH"

# Default language/locale (en_US)
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Wayland-first hints for apps launched from a terminal inside Sway
export MOZ_ENABLE_WAYLAND=1
export NIXOS_OZONE_WL=1


# Load local secrets (outside version control)
if [ -f "$HOME/.secrets.zsh" ]; then
  source "$HOME/.secrets.zsh"
fi
