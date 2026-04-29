#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing fcitx5..."

log_info "Installing fcitx5 and related packages..."
if ! sudo pacman -S --needed --noconfirm fcitx5-im fcitx5-chinese-addons fcitx5-pinyin-zhwiki fcitx5-configtool fcitx5-material-color; then
    log_error "Failed to install fcitx5"
    exit 1
fi

log_info "fcitx5 installed successfully"
exit 0