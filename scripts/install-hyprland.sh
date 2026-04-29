#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing Hyprland and related components..."

HYPRLAND_PACKAGES=(
    hyprland
    xdg-desktop-portal-hyprland
    xdg-desktop-portal
    kitty
    dolphin
    wofi    
    qt5-wayland
    qt6-wayland
    waybar
    hyprshot
    swaync
    hyprlock
    hyprpaper
    hypridle
    brightnessctl
    # polkit-kde-agent
    hyprpolkitagent   
    sddm
)

log_info "Installing Hyprland and related components..."
if ! sudo pacman -S --needed --noconfirm "${HYPRLAND_PACKAGES[@]}"; then
    log_error "Failed to install Hyprland packages"
    exit 1
fi

HYPRLAND_AUR_PACKAGES=(
    hyprshutdown
)

log_info "Installing Hyprland AUR packages..."
if ! yay -S --needed --noconfirm "${HYPRLAND_AUR_PACKAGES[@]}"; then
    log_error "Failed to install Hyprland AUR packages"
    exit 1
fi

# Enable polkit service
# log_info "Enabling polkit service..."
# systemctl enable polkit || {
#     log_error "Failed to enable polkit service"
#     exit 1
# }


# Enable SDDM service
log_info "Enabling SDDM service..."
sudo systemctl enable sddm || {
    log_error "Failed to enable SDDM service"
    exit 1
}


log_info "Hyprland installation completed!"
exit 0
