#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing system dependencies..."

PACMAN_packages=(
    # Audio
    pavucontrol

    # Clipboard
    wl-clipboard
    cliphist
    wl-clip-persist

    # Download tools
    curl
    wget

    # Filesystem & disk tools
    btrfs-progs
    rsync
    udisks2

    # Development tools
    git
    nvim

    # System info & monitoring
    fastfetch
    htop
    nvtop
    less

    # Media & image viewers
    mpv
    gpicview

    # Multimedia & image processing
    ffmpeg
    imagemagick
    resvg
    poppler

    # Archive tools
    unzip
    7zip

    # Network storage & filesystem
    gvfs
    mtools
    smbclient
    cifs-utils
    nfs-utils
    fuse3

    # CLI productivity tools
    jq
    fd
    ripgrep
    fzf
    zoxide
    bat
    thefuck
    trash-cli

    # Backup
    timeshift
)

log_info "Installing official packages..."
if ! sudo pacman -S --needed --noconfirm "${PACMAN_packages[@]}"; then
    log_error "Failed to install some official packages"
    exit 1
fi

# log_info "Installing AUR packages via yay..."
# AUR_PACKAGES=(
#     mint-y-icons
#     mint-themes
# )
# if command -v yay >/dev/null; then
#     yay -S --needed --noconfirm "${AUR_PACKAGES[@]}" || log_warn "Some AUR packages failed to install"
# fi

log_info "System dependencies installation complete"
exit 0