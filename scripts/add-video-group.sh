#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

log_step "Adding user to video and render groups..."

for group in video render; do
    if groups | grep -qw "$group"; then
        log_info "$USER is already in $group group"
    else
        sudo usermod -aG "$group" "$USER"
        log_info "Added $USER to $group group"
    fi
done

log_info "Please logout and login again for group changes to take effect"
exit 0