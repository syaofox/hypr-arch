#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing Hyprland and related components..."

HYPRLAND_PACKAGES=(
    hyprland
    xdg-desktop-portal-hyprland
    kitty
    dolphin
    wofi
    polkit-kde-agent
    qt5-wayland
    qt6-wayland
    waybar
    hyprshot
    swaync
    hyprlock
    hyprpaper
    hypridle
    brightnessctl
)

log_info "Installing Hyprland and related components..."
if ! sudo pacman -S --needed --noconfirm "${HYPRLAND_PACKAGES[@]}"; then
    log_error "Failed to install Hyprland packages"
    exit 1
fi

# Install Nvidia Open Kernel Module drivers (if Nvidia GPU detected)
if lspci | grep -i nvidia > /dev/null 2>&1; then
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
else
    log_info "No Nvidia GPU detected, skipping Nvidia driver installation"
fi

# Install SDDM display manager
log_info "Installing SDDM display manager..."
if ! sudo pacman -S --needed --noconfirm sddm; then
    log_error "Failed to install SDDM"
    exit 1
fi

# Enable services
log_info "Enabling system services..."
sudo systemctl enable sddm || {
    log_error "Failed to enable SDDM service"
    exit 1
}

log_info "Hyprland installation completed!"
exit 0
