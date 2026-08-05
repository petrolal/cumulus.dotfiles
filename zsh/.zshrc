# ~/.zshrc — clean, fast, developer-focused (no oh-my-zsh, to keep startup fast and dependency-free)

# ── History ──
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# ── Completion ──
autoload -Uz compinit
compinit -C   # -C skips the security re-check every shell start, big speedup; run `compinit` bare occasionally
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# ── Keybindings ──
bindkey -e   # emacs-style line editing (Ctrl-A/E/W etc.)

# ── SSH agent (persist across shells, don't spawn a new one every terminal) ──
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)" > /dev/null
fi

# ── Prompt: minimal, git-aware, fast (no external framework) ──
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PROMPT='%F{blue}%~%f%F{yellow}${vcs_info_msg_0_}%f %F{green}❯%f '

# ── General aliases ──
alias ll='ls -alh --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias vim='nvim'
alias vi='nvim'
alias c='clear'
alias reload='source ~/.zshrc'

# ── Git aliases ──
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias gst='git stash'

# ── Docker aliases ──
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias dexec='docker exec -it'
alias dlogs='docker logs -f'
alias dprune='docker system prune -f'

# ── Kubernetes aliases ──
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deploy'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete -f'
alias klog='kubectl logs -f'
alias kctx='kubectl config use-context'
alias kns='kubectl config set-context --current --namespace'

# ── tmux ──
alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tls='tmux ls'

# ── Environment ──
export EDITOR=nvim
export VISUAL=nvim
export PATH="$HOME/.local/bin:$PATH"

# Wayland-first hints for apps launched from a terminal inside Sway
export MOZ_ENABLE_WAYLAND=1
export NIXOS_OZONE_WL=1

# ── Old (pre-Sway) custom config ──
[ -f ~/.zshrc_custom ] && source ~/.zshrc_custom

##################################################################
#
# Set NVM directory
#
##############################################################
export NVM_DIR="$HOME/.nvm"

# Load NVM if the script exists
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Load NVM bash completion if it exists
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"


####################################################################
#
# SdkMan
# THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
#
###################################################################
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
. "$HOME/.cargo/env"

