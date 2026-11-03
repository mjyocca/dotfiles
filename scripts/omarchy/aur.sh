#!/usr/bin/env bash
# AUR layer: Install AUR packages interactively
# Omarchy-only (not in Linux base)
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

source "$(dirname "${BASH_SOURCE[0]}")/../shared/detect-os.sh"

if [[ "$(get_os)" != "omarchy" ]]; then
    fatal "This script is for Omarchy only"
fi

info "Installing AUR packages..."

if ! command_exists yay; then
    fatal "yay is not installed. Please install yay first."
fi

# Read AUR package list
aur_list="$(dirname "${BASH_SOURCE[0]}")/../manifests/aur/packages-aur.txt"

if [[ ! -f "$aur_list" ]]; then
    warn "AUR package list not found at $aur_list"
    warn "Skipping AUR installation"
    exit 0
fi

# Parse and install AUR packages interactively
info "Reading AUR package list from $aur_list"

# Read packages from list (skip comments and empty lines)
packages=()
while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    packages+=("$line")
done < "$aur_list"

if [[ ${#packages[@]} -eq 0 ]]; then
    info "No AUR packages to install"
    exit 0
fi

info "Installing ${#packages[@]} AUR packages..."

# Install packages interactively (yay will prompt for PKGBUILD review)
for pkg in "${packages[@]}"; do
    info "Installing $pkg..."
    yay -S --needed "$pkg"
done

success "AUR packages installed"
