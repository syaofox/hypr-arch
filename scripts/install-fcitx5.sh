#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Installing fcitx5..."

log_info "Installing fcitx5 and related packages..."
if ! sudo pacman -S --needed --noconfirm fcitx5-im fcitx5-chinese-addons fcitx5-pinyin-zhwiki fcitx5-configtool fcitx5-material-color; then
    log_error "Failed to install fcitx5"
    exit 1
fi

log_info "Configuring fcitx5 environment variables..."
fcitx5_env_file="/etc/environment.d/99-fcitx5.conf"
if [ ! -f "$fcitx5_env_file" ]; then
    echo "# fcitx5 input method" | sudo tee "$fcitx5_env_file" > /dev/null
    echo "QT_IM_MODULE=fcitx" | sudo tee -a "$fcitx5_env_file" > /dev/null
    echo "XMODIFIERS=@im=fcitx" | sudo tee -a "$fcitx5_env_file" > /dev/null
    log_info "Created fcitx5 environment config: $fcitx5_env_file"
else
    log_info "fcitx5 environment config already exists"
fi

log_info "fcitx5 installed successfully"
exit 0