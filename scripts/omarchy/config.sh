#!/usr/bin/env bash
# Config layer: Apply Omarchy-specific configuration
# Omarchy implementation (Hyprland, themes, etc.)
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

source "$(dirname "${BASH_SOURCE[0]}")/../shared/detect-os.sh"

if [[ "$(get_os)" != "omarchy" ]]; then
    fatal "This script is for Omarchy only"
fi

info "Applying Omarchy-specific configuration..."

# Omarchy uses dotfiles in ~/.config/ for Hyprland, Waybar, etc.
# Configuration is managed via mise symlink-each
info "Omarchy configuration managed via dotfiles in ~/.config/"

success "Omarchy configuration applied"
