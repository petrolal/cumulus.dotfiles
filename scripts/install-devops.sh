#!/usr/bin/env bash
#
# install-devops.sh — install the main DevOps toolchain:
#
#   - Docker (Engine, CLI, containerd, buildx, compose plugin) via the
#     official Docker apt/pacman repo — always tracks Docker's own latest
#     stable release, not the (often stale) distro-packaged version.
#   - Terraform (HashiCorp) via the official apt repo, or the community
#     `terraform-bin` AUR-equivalent path (pacman's official `terraform`
#     package) on Arch.
#   - Ansible via apt/pacman (both ship reasonably current versions;
#     no need for a third-party repo here).
#
# Also adds the current user to the `docker` group so `docker` can be run
# without sudo (takes effect on next login).
#
# Idempotent: safe to re-run; skips steps whose tool/repo is already present.
#
# Supports Ubuntu (apt) and Arch (pacman).
#
# Usage:
#   ./install-devops.sh            # install everything below
#   ./install-devops.sh --dry-run  # preview commands, change nothing
#
set -euo pipefail

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -h|--help) grep '^#' "$0" | sed 's/^#//'; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

log() { printf '\033[1;34m[devops]\033[0m %s\n' "$*"; }
run() { if $DRY_RUN; then echo "+ $*"; else eval "$@"; fi }

install_docker_apt() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed: $(docker --version)"
  else
    log "Adding Docker's official apt repo..."
    run "sudo apt update"
    run "sudo apt install -y ca-certificates curl gnupg"
    run "sudo install -m 0755 -d /etc/apt/keyrings"
    if [ ! -f /etc/apt/keyrings/docker.gpg ] || $DRY_RUN; then
      run "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
    fi
    run "sudo chmod a+r /etc/apt/keyrings/docker.gpg"
    if [ ! -f /etc/apt/sources.list.d/docker.list ] || $DRY_RUN; then
      run "echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(. /etc/os-release && echo \\\"\$VERSION_CODENAME\\\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"
    fi
    log "Installing Docker packages..."
    run "sudo apt update"
    run "sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
  fi
}

install_docker_pacman() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed: $(docker --version)"
  else
    log "Installing Docker via pacman..."
    run "sudo pacman -Syu --needed --noconfirm docker docker-buildx docker-compose"
  fi
  run "sudo systemctl enable --now docker.service"
}

install_terraform_apt() {
  if command -v terraform >/dev/null 2>&1; then
    log "Terraform already installed: $(terraform version | head -1)"
    return
  fi
  log "Adding HashiCorp's official apt repo..."
  run "sudo apt update"
  run "sudo apt install -y gnupg software-properties-common curl"
  if [ ! -f /etc/apt/keyrings/hashicorp.gpg ] || $DRY_RUN; then
    run "curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg"
  fi
  if [ ! -f /etc/apt/sources.list.d/hashicorp.list ] || $DRY_RUN; then
    run "echo \"deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com \$(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null"
  fi
  log "Installing Terraform..."
  run "sudo apt update"
  run "sudo apt install -y terraform"
}

install_terraform_pacman() {
  if command -v terraform >/dev/null 2>&1; then
    log "Terraform already installed: $(terraform version | head -1)"
    return
  fi
  log "Installing Terraform via pacman (community/extra repo)..."
  run "sudo pacman -Syu --needed --noconfirm terraform"
}

install_ansible_apt() {
  if command -v ansible >/dev/null 2>&1; then
    log "Ansible already installed: $(ansible --version | head -1)"
    return
  fi
  log "Installing Ansible via apt..."
  run "sudo apt update"
  run "sudo apt install -y ansible"
}

install_ansible_pacman() {
  if command -v ansible >/dev/null 2>&1; then
    log "Ansible already installed: $(ansible --version | head -1)"
    return
  fi
  log "Installing Ansible via pacman..."
  run "sudo pacman -Syu --needed --noconfirm ansible"
}

add_user_to_docker_group() {
  if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    log "$USER is already in the docker group."
  else
    log "Adding $USER to the docker group (re-login required to take effect)..."
    run "sudo usermod -aG docker $USER"
  fi
}

main() {
  if command -v apt >/dev/null 2>&1; then
    install_docker_apt
    install_terraform_apt
    install_ansible_apt
  elif command -v pacman >/dev/null 2>&1; then
    install_docker_pacman
    install_terraform_pacman
    install_ansible_pacman
  else
    log "No supported package manager found (apt/pacman) — install manually:"
    log "  docker, terraform, ansible"
    exit 1
  fi

  add_user_to_docker_group

  log "Done. Versions:"
  if $DRY_RUN; then
    log "  (skipped version checks in dry-run)"
  else
    command -v docker    >/dev/null 2>&1 && docker --version
    command -v terraform >/dev/null 2>&1 && terraform version | head -1
    command -v ansible   >/dev/null 2>&1 && ansible --version | head -1
  fi
  log "If you were just added to the docker group, log out/in (or 'newgrp docker') before running docker without sudo."
}

main "$@"
