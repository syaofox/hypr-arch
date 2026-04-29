#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"


log_step "Installing Node.js via nvm..."

if [ "$EUID" -eq 0 ]; then
    log_error "Error: Do not run this script as root. Please run it as a regular user."
    exit 1
fi

export NVM_DIR="$HOME/.config/nvm"

if [ ! -d "$NVM_DIR" ]; then
    log_info "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
fi

log_info "Installing Node.js 25..."
bash -c "source \"$NVM_DIR/nvm.sh\" && nvm install 25 && nvm alias default 25"

log_info "Node.js has been successfully installed!"
log_info "You can now use 'node' and 'npm'"
exit 0