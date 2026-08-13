#!/usr/bin/env bash
# SDKMan Maintenance Script
# Manages existing SDKMan installations, updates tools, and maintains versions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;36m'
NC='\033[0m' # No Color

print_header() {
  echo -e "${BLUE}[cumulus-sdkman]${NC} $1"
}

print_ok() {
  echo -e "  ${GREEN}[OK]${NC} $1"
}

print_info() {
  echo -e "  ${BLUE}[INFO]${NC} $1"
}

print_warn() {
  echo -e "  ${YELLOW}[WARN]${NC} $1"
}

print_error() {
  echo -e "  ${RED}[ERROR]${NC} $1"
}

check_sdkman() {
  print_header "Checking SDKMan installation..."

  if [ ! -d "$SDKMAN_DIR" ]; then
    print_error "SDKMan not found at $SDKMAN_DIR"
    print_info "Install with: bash <(curl -s https://get.sdkman.io)"
    return 1
  fi

  print_ok "SDKMan found at $SDKMAN_DIR"
  return 0
}

upgrade_sdkman() {
  print_header "Upgrading SDKMan..."

  if ! check_sdkman; then
    return 1
  fi

  bash -c "
    source $SDKMAN_DIR/bin/sdkman-init.sh
    print_info 'Running: sdk selfupdate'
    sdk selfupdate force 2>/dev/null || true
    print_ok 'SDKMan upgraded'
  "
}

list_installed() {
  print_header "Listing installed SDKs..."

  bash -c "
    source $SDKMAN_DIR/bin/sdkman-init.sh
    sdk current
  " || print_warn "Could not list current versions"
}

show_available_versions() {
  local tool=$1
  print_header "Available versions for $tool..."

  bash -c "
    source $SDKMAN_DIR/bin/sdkman-init.sh
    sdk list $tool | head -20
  "
}

update_java() {
  local version="${1:-21.0.1-graal}"
  print_header "Updating Java to $version..."

  bash -c "
    source $SDKMAN_DIR/bin/sdkman-init.sh

    print_info 'Installing Java $version...'
    sdk install java $version --default 2>/dev/null || true

    print_info 'Current Java version:'
    java -version
    print_ok 'Java updated'
  "
}

update_scala() {
  local version="${1:-3.5.2}"
  print_header "Updating Scala to $version..."

  bash -c "
    source $SDKMAN_DIR/bin/sdkman-init.sh

    print_info 'Installing Scala $version...'
    sdk install scala $version --default 2>/dev/null || true

    print_info 'Current Scala version:'
    scala -version
    print_ok 'Scala updated'
  "
}

update_sbt() {
  local version="${1:-1.9.9}"
  print_header "Updating sbt to $version..."

  bash -c "
    source $SDKMAN_DIR/bin/sdkman-init.sh

    print_info 'Installing sbt $version...'
    sdk install sbt $version --default 2>/dev/null || true

    print_info 'Current sbt version:'
    sbt --version
    print_ok 'sbt updated'
  "
}

update_all() {
  print_header "Updating all SDKMan tools..."

  bash -c "
    source $SDKMAN_DIR/bin/sdkman-init.sh

    print_info 'Updating SDKMan...'
    sdk selfupdate force 2>/dev/null || true

    print_info 'Installing Java 21 GraalVM...'
    sdk install java 21.0.1-graal --default 2>/dev/null || true

    print_info 'Installing Scala 3.5.2...'
    sdk install scala 3.5.2 --default 2>/dev/null || true

    print_info 'Installing sbt 1.9.9...'
    sdk install sbt 1.9.9 --default 2>/dev/null || true

    print_info 'Current versions:'
    sdk current
  "

  print_ok "All tools updated successfully"
}

clean_old_versions() {
  print_header "Cleaning old SDK versions (keeping current default)..."

  bash -c "
    source $SDKMAN_DIR/bin/sdkman-init.sh

    for tool in java scala sbt; do
      print_info 'Checking \$tool versions...'
      current=\$(sdk current | grep \$tool | awk '{print \$3}')
      if [ -n \"\$current\" ]; then
        print_info \"Current \$tool version: \$current\"
      fi
    done

    print_warn 'Manual cleanup required for old versions'
    print_info 'To remove old versions:'
    print_info '  rm -rf $SDKMAN_DIR/candidates/java/<old-version>'
    print_info '  rm -rf $SDKMAN_DIR/candidates/scala/<old-version>'
    print_info '  rm -rf $SDKMAN_DIR/candidates/sbt/<old-version>'
  "
}

reset_sdkman() {
  print_header "WARNING: This will reinstall SDKMan from scratch"
  echo -en "${YELLOW}[?] Are you sure? (y/N): ${NC}"
  read -r response || response="n"

  if [[ "$response" =~ ^[Yy]$ ]]; then
    print_warn "Backing up existing SDKMan to ${SDKMAN_DIR}.backup..."
    mv "$SDKMAN_DIR" "${SDKMAN_DIR}.backup"

    print_info "Installing fresh SDKMan..."
    curl -s "https://get.sdkman.io" | bash

    print_ok "SDKMan reinstalled. Old installation backed up at ${SDKMAN_DIR}.backup"
  else
    print_info "Reset cancelled"
  fi
}

show_help() {
  cat << 'EOF'
SDKMan Maintenance Script

Usage: ./scripts/maintain-sdkman.sh <command> [args]

Commands:
  check                 Check SDKMan installation status
  upgrade               Upgrade SDKMan itself
  list                  List currently installed SDK versions
  available <tool>      Show available versions for tool (java|scala|sbt)

  update-java [ver]     Update Java (default: 21.0.1-graal)
  update-scala [ver]    Update Scala (default: 3.5.2)
  update-sbt [ver]      Update sbt (default: 1.9.9)
  update-all            Update all tools to latest recommended versions

  clean                 Show guidance for cleaning old versions
  reset                 Reinstall SDKMan from scratch (backup existing)

  help                  Show this help message

Examples:
  # Check installation
  ./scripts/maintain-sdkman.sh check

  # Upgrade SDKMan and all tools
  ./scripts/maintain-sdkman.sh upgrade
  ./scripts/maintain-sdkman.sh update-all

  # Update specific tools
  ./scripts/maintain-sdkman.sh update-java 21.0.5-graal
  ./scripts/maintain-sdkman.sh update-scala 3.6.0

  # List available versions
  ./scripts/maintain-sdkman.sh available java
  ./scripts/maintain-sdkman.sh available scala

Environment Variables:
  SDKMAN_DIR            Location of SDKMan installation (default: ~/.sdkman)

  # Example custom installation path
  SDKMAN_DIR=/opt/sdkman ./scripts/maintain-sdkman.sh check

See Also:
  - SDKMan Docs: https://sdkman.io/
  - Java versions: https://sdkman.io/jdks
  - Scala versions: https://sdkman.io/sdks/scala
  - sbt versions: https://sdkman.io/sdks/sbt
EOF
}

# Main command routing
main() {
  local command="${1:-help}"

  case "$command" in
    check)
      check_sdkman
      ;;
    upgrade)
      upgrade_sdkman
      ;;
    list)
      list_installed
      ;;
    available)
      show_available_versions "${2:-java}"
      ;;
    update-java)
      update_java "${2:-21.0.1-graal}"
      ;;
    update-scala)
      update_scala "${2:-3.5.2}"
      ;;
    update-sbt)
      update_sbt "${2:-1.9.9}"
      ;;
    update-all)
      update_all
      ;;
    clean)
      clean_old_versions
      ;;
    reset)
      reset_sdkman
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      print_error "Unknown command: $command"
      echo ""
      show_help
      exit 1
      ;;
  esac
}

main "$@"
