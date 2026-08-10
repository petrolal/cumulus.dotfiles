//! `cumulus-install-devops` — install Docker, Terraform, and Ansible. Ports
//! `install-devops.sh`.

use super::{have, parse_dry_run, sh_capture, Installer};
use crate::context::Context;
use crate::error::{Error, Result};

const HELP: &str = "\
install-devops.sh — install the main DevOps toolchain: Docker, Terraform,
and Ansible, and add the current user to the docker group.

Supports Ubuntu (apt) and Arch (pacman).

Usage:
  cumulus-install-devops            # install everything
  cumulus-install-devops --dry-run  # preview commands, change nothing
";

fn username() -> String {
    std::env::var("USER")
        .ok()
        .or_else(crate::util::current_username)
        .unwrap_or_default()
}

pub fn run(_ctx: &Context, args: &[String]) -> Result<()> {
    let Some(dry_run) = parse_dry_run(args, HELP)? else {
        return Ok(());
    };
    let inst = Installer::new("devops", dry_run);

    if have("apt") {
        install_docker_apt(&inst);
        install_terraform_apt(&inst);
        install_ansible_apt(&inst);
    } else if have("pacman") {
        install_docker_pacman(&inst);
        install_terraform_pacman(&inst);
        install_ansible_pacman(&inst);
    } else {
        inst.log("No supported package manager found (apt/pacman) — install manually:");
        inst.log("  docker, terraform, ansible");
        return Err(Error::with_code("", 1));
    }

    add_user_to_docker_group(&inst);

    inst.log("Done. Versions:");
    if dry_run {
        inst.log("  (skipped version checks in dry-run)");
    } else {
        if have("docker") {
            println!("{}", sh_capture("docker --version"));
        }
        if have("terraform") {
            println!("{}", sh_capture("terraform version | head -1"));
        }
        if have("ansible") {
            println!("{}", sh_capture("ansible --version | head -1"));
        }
    }
    inst.log("If you were just added to the docker group, log out/in (or 'newgrp docker') before running docker without sudo.");
    Ok(())
}

fn install_docker_apt(inst: &Installer) {
    if have("docker") {
        inst.log(&format!(
            "Docker already installed: {}",
            sh_capture("docker --version")
        ));
    } else {
        inst.log("Adding Docker's official apt repo...");
        inst.run("sudo apt update");
        inst.run("sudo apt install -y ca-certificates curl gnupg");
        inst.run("sudo install -m 0755 -d /etc/apt/keyrings");
        if !std::path::Path::new("/etc/apt/keyrings/docker.gpg").exists() || inst.dry_run() {
            inst.run("curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg");
        }
        inst.run("sudo chmod a+r /etc/apt/keyrings/docker.gpg");
        if !std::path::Path::new("/etc/apt/sources.list.d/docker.list").exists() || inst.dry_run() {
            inst.run("echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \\\"$VERSION_CODENAME\\\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null");
        }
        inst.log("Installing Docker packages...");
        inst.run("sudo apt update");
        inst.run("sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin");
    }
}

fn install_docker_pacman(inst: &Installer) {
    if have("docker") {
        inst.log(&format!(
            "Docker already installed: {}",
            sh_capture("docker --version")
        ));
    } else {
        inst.log("Installing Docker via pacman...");
        inst.run("sudo pacman -Syu --needed --noconfirm docker docker-buildx docker-compose");
    }
    inst.run("sudo systemctl enable --now docker.service");
}

fn install_terraform_apt(inst: &Installer) {
    if have("terraform") {
        inst.log(&format!(
            "Terraform already installed: {}",
            sh_capture("terraform version | head -1")
        ));
        return;
    }
    inst.log("Adding HashiCorp's official apt repo...");
    inst.run("sudo apt update");
    inst.run("sudo apt install -y gnupg software-properties-common curl");
    if !std::path::Path::new("/etc/apt/keyrings/hashicorp.gpg").exists() || inst.dry_run() {
        inst.run("curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg");
    }
    if !std::path::Path::new("/etc/apt/sources.list.d/hashicorp.list").exists() || inst.dry_run() {
        inst.run("echo \"deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null");
    }
    inst.log("Installing Terraform...");
    inst.run("sudo apt update");
    inst.run("sudo apt install -y terraform");
}

fn install_terraform_pacman(inst: &Installer) {
    if have("terraform") {
        inst.log(&format!(
            "Terraform already installed: {}",
            sh_capture("terraform version | head -1")
        ));
        return;
    }
    inst.log("Installing Terraform via pacman (community/extra repo)...");
    inst.run("sudo pacman -Syu --needed --noconfirm terraform");
}

fn install_ansible_apt(inst: &Installer) {
    if have("ansible") {
        inst.log(&format!(
            "Ansible already installed: {}",
            sh_capture("ansible --version | head -1")
        ));
        return;
    }
    inst.log("Installing Ansible via apt...");
    inst.run("sudo apt update");
    inst.run("sudo apt install -y ansible");
}

fn install_ansible_pacman(inst: &Installer) {
    if have("ansible") {
        inst.log(&format!(
            "Ansible already installed: {}",
            sh_capture("ansible --version | head -1")
        ));
        return;
    }
    inst.log("Installing Ansible via pacman...");
    inst.run("sudo pacman -Syu --needed --noconfirm ansible");
}

fn add_user_to_docker_group(inst: &Installer) {
    let user = username();
    let in_group = sh_capture(&format!(
        "id -nG {user} | tr ' ' '\\n' | grep -qx docker && echo yes || echo no"
    ));
    if in_group == "yes" {
        inst.log(&format!("{user} is already in the docker group."));
    } else {
        inst.log(&format!(
            "Adding {user} to the docker group (re-login required to take effect)..."
        ));
        inst.run(&format!("sudo usermod -aG docker {user}"));
    }
}
