#!/usr/bin/env bash
# Config layer: Apply Linux-specific configuration
# Linux base implementation
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

if ! is_linux; then
    fatal "This script is for Linux only"
fi

info "Applying Linux configuration..."

# Linux-specific configuration would go here
# Examples:
# - gsettings for GNOME
# - dconf for general Linux desktop settings
# - X11/Wayland config

info "Linux configuration managed via dotfiles in ~/.config/"

success "Linux configuration applied"
