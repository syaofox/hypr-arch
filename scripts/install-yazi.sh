#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing yazi and dependencies..."

PACMAN_packages=(
    yazi
    ffmpeg
    7zip
    jq
    poppler
    fd
    ripgrep
    fzf
    zoxide
    resvg
    imagemagick
)

if ! sudo pacman -S --needed --noconfirm "${PACMAN_packages[@]}"; then
    log_error "Failed to install some packages"
    exit 1
fi

log_info "yazi installation complete"
exit 0