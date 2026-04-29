#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing Nvidia drivers..."

if ! lspci | grep -i nvidia > /dev/null 2>&1; then
    log_info "No Nvidia GPU detected, skipping Nvidia driver installation"
    exit 0
fi

log_info "Nvidia GPU detected, installing drivers..."

NVIDIA_PACKAGES=(
    nvidia-open-dkms
    dkms
    libva-nvidia-driver
)

if ! sudo pacman -S --needed --noconfirm "${NVIDIA_PACKAGES[@]}"; then
    log_error "Failed to install Nvidia drivers"
    exit 1
fi

log_info "Nvidia drivers installation complete"
exit 0
