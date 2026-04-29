#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Enable Chinese locale (zh_CN.UTF-8)..."

LOCALE_GEN="/etc/locale.gen"

if [[ ! -f "$LOCALE_GEN" ]]; then
    log_error "locale.gen not found: $LOCALE_GEN"
    exit 1
fi

if grep -q "^#.*zh_CN.UTF-8 UTF-8" "$LOCALE_GEN"; then
    sudo sed -i 's/^#.*zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' "$LOCALE_GEN"
    log_info "Enabled zh_CN.UTF-8 in locale.gen"
elif grep -q "^zh_CN.UTF-8 UTF-8" "$LOCALE_GEN"; then
    log_info "zh_CN.UTF-8 already enabled in locale.gen"
fi

log_info "Generating locales..."
sudo locale-gen || exit 1

log_info "Setting system locale to English (keep UI in English)..."
echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf > /dev/null

log_info "Chinese locale enabled, system stays in English"
exit 0

