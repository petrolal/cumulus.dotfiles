# ── Completion ──
# oh-my-zsh already runs compinit, but the flags/zstyles below tune it.
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# ── Keybindings ──
bindkey -e   # emacs-style line editing (Ctrl-A/E/W etc.)
