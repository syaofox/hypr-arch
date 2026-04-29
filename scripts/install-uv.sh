#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"


log_step "Installing uv Python package manager..."

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Error: Do not run this script as root. Please run it as a regular user with sudo privileges."
    exit 1
fi

# Install uv from official repository
log_info "Installing uv from Extra repository..."
if ! sudo pacman -S --needed --noconfirm uv; then
    log_error "Failed to install uv"
    exit 1
fi

log_info "uv has been successfully installed!"
log_info "You can now use 'uv' to manage Python packages"
exit 0