#!/usr/bin/env bash
#
# install-sdkman.sh — install SDKMAN and the JVM toolchain it manages:
#
#   - SDKMAN itself (https://get.sdkman.io)
#   - Java — interactive: lists candidates via `sdk list java` and asks
#     which identifier to install (there's no single "latest stable" for
#     Java since SDKMAN tracks several vendors/LTS lines at once). Set
#     JAVA_VERSION=<identifier> to install non-interactively/unattended
#     (e.g. in scripts, CI, or when stdin isn't a TTY).
#   - Kotlin, Maven, Gradle — always the latest stable release of each,
#     `sdk install <candidate>` with no version resolves to that automatically.
#
# Idempotent: safe to re-run; sdkman skips candidates already at the
# requested version. Candidate installs auto-confirm SDKMAN's "set as
# default? (Y/n)" prompt (default answer) so this never blocks unattended.
#
# zsh/zsh_config/99-sdkman-cargo.zsh already sources sdkman-init.sh at shell
# startup, so once this script has run, `java`/`kotlin`/`mvn`/`gradle` are on
# PATH in any new shell.
#
# Usage:
#   ./install-sdkman.sh            # install sdkman + kotlin/maven/gradle, prompt for Java
#   ./install-sdkman.sh --dry-run  # preview commands, change nothing
#   JAVA_VERSION=21.0.7-tem ./install-sdkman.sh   # install Java non-interactively
#
# No `-u`: sdkman-init.sh itself references unset variables internally, so
# nounset mode breaks sourcing it.
set -o pipefail

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h|--help) grep '^#' "$0" | sed 's/^#//'; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

log() { printf '\033[1;34m[sdkman]\033[0m %s\n' "$*"; }
run() { if $DRY_RUN; then echo "+ $*"; else eval "$@"; fi }

SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
export SDKMAN_DIR

install_sdkman() {
  if [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]; then
    log "OK (already installed): sdkman ($SDKMAN_DIR)"
    return
  fi

  log "Installing SDKMAN..."
  run "curl -s \"https://get.sdkman.io\" | bash"
  $DRY_RUN && return

  # The upstream installer always appends its own init snippet to ~/.zshrc.
  # In this repo ~/.zshrc is a symlink into the tracked zsh/.zshrc, so that
  # write would land in the repo itself — duplicating what
  # zsh_config/99-sdkman-cargo.zsh already sources, and hardcoding this
  # machine's $HOME. Strip it back out.
  local zshrc="$HOME/.zshrc"
  if [ -f "$zshrc" ] && grep -q 'FOR SDKMAN TO WORK' "$zshrc" 2>/dev/null; then
    log "Removing SDKMAN's auto-appended snippet from $zshrc (already handled by zsh_config/99-sdkman-cargo.zsh)..."
    sed -i -e '/^#.*FOR SDKMAN TO WORK/,/sdkman-init\.sh"$/d' -e '${/^$/d}' "$zshrc"
  fi
}

# SDKMAN prompts "Do you want candidate-version to be set as default? (Y/n)"
# after every install; feeding it an empty stdin accepts the (Y) default
# without needing a real TTY.
sdk_install() { sdk install "$@" < /dev/null; }

install_java() {
  local java_version="${JAVA_VERSION:-}"

  if [ -z "$java_version" ]; then
    if [ ! -t 0 ]; then
      log "No TTY and JAVA_VERSION not set — skipping Java."
      log "Re-run with JAVA_VERSION=<sdk-identifier> to install it non-interactively."
      return
    fi
    log "Available Java versions (the Identifier column is what to enter below):"
    sdk list java
    read -rp "Enter the Java version identifier to install (blank to skip): " java_version
    if [ -z "$java_version" ]; then
      log "Skipping Java install."
      return
    fi
  fi

  log "Installing Java $java_version via sdkman..."
  sdk_install java "$java_version"
}

install_latest() {
  local candidate="$1"
  log "Installing latest stable $candidate via sdkman..."
  sdk_install "$candidate"
}

main() {
  $DRY_RUN && log "DRY RUN — no changes will be made"

  install_sdkman

  if $DRY_RUN; then
    log "+ sdk install java <version>  (interactive prompt, or \$JAVA_VERSION)"
    log "+ sdk install kotlin"
    log "+ sdk install maven"
    log "+ sdk install gradle"
    return
  fi

  # shellcheck disable=SC1091
  \. "$SDKMAN_DIR/bin/sdkman-init.sh"

  install_java
  install_latest kotlin
  install_latest maven
  install_latest gradle

  log "Done. Open a new shell (or 'source ~/.zshrc') to pick up java/kotlin/mvn/gradle on PATH."
}

main "$@"
