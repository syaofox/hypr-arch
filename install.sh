#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/scripts/utils.sh"

[[ $EUID -eq 0 ]] && log_error "Do not run this script as root. Use a regular user with sudo privileges." && exit 1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Function to ask user what to do on failure
ask_on_failure() {
    local step_name="$1"
    log_error "${step_name} failed"
    echo ""
    log_info "What would you like to do?"
    echo "  [r] Retry this step"
    echo "  [s] Skip this step"
    echo "  [e] Exit installation"
    echo ""
    read -p "Enter your choice [r/s/e]: " choice

    case $choice in
        r|R) return 1 ;;
        s|S) log_info "Skipping: ${step_name}"; echo ""; return 0 ;;
        e|E) log_info "Exiting installation..."; exit 1 ;;
        *) echo "Invalid choice. Please try again."; ask_on_failure "$step_name" ;;
    esac
}

# Function to run a step with error handling
run_step() {
    local step_name="$1"
    shift
    local cmd="$*"

    while true; do
        log_info "Running: ${step_name}..."
        if eval "$cmd"; then
            log_info "${step_name} completed successfully!"
            echo ""
            return 0
        else
            ask_on_failure "$step_name" || continue
            return 0
        fi
    done
}



run_step "Upgrade system dependencies" "./scripts/upgrade-deps.sh"
run_step "Install AUR helper" "./scripts/install-yay.sh"
run_step "Install system dependencies" "./scripts/install-deps.sh"
run_step "Install Hyprland" "./scripts/install-hyprland.sh"


run_step "Install yazi" "./scripts/install-yazi.sh"
run_step "Install Chinese locale" "./scripts/install-locale.sh"
run_step "Install Docker" "./scripts/install-docker.sh"
run_step "Install uv Python package manager" "./scripts/install-uv.sh"
run_step "Install Node.js via nvm" "./scripts/install-nodejs.sh"
run_step "Install fonts" "./scripts/install-fonts.sh"
run_step "Configure Flathub" "./scripts/install-flathub.sh"
run_step "Install fcitx5" "./scripts/install-fcitx5.sh"

run_step "Add user to video/render groups" "./scripts/add-video-group.sh"
run_step "Install fish shell" "./scripts/install-fish.sh"
run_step "Deploy configuration files" "./scripts/deploy-dotfiles.sh"

echo ""
log_info "═══════════════════════════════════════"
log_info "✓ All installation steps completed!"
log_info "═══════════════════════════════════════"
echo ""
log_info "Please reboot your system to apply all changes (including group membership updates for video, render)."

