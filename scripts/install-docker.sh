#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/utils.sh"

install_docker() {
    log_step "Installing Docker & Docker Compose..."

    log_info "Installing docker and docker compose plugin..."
    sudo pacman -S --needed --noconfirm docker

    log_info "Enabling and starting docker service..."
    sudo systemctl enable --now docker.service

    log_info "Adding user to docker group..."
    if ! getent group docker > /dev/null; then
        sudo groupadd docker
    fi
    sudo gpasswd -a "$USER" docker

    log_info "Configuring NVIDIA container toolkit..."
    if command -v nvidia-ctk &>/dev/null; then
        sudo nvidia-ctk runtime configure --runtime=docker
        sudo systemctl restart docker
    else
        log_warn "nvidia-container-toolkit not installed, skipping GPU runtime config"
    fi

    log_info "Docker installation complete!"
    log_info "Run 'newgrp docker' to activate group permissions"
}

install_docker "$@"