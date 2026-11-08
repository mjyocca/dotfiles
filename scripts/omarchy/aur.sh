#!/usr/bin/env bash
# Omarchy AUR interface: preserve interactive PKGBUILD review.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../shared/detect-os.sh"

install_aur_packages() {
    is_linux || fatal 'This script is for Linux only'
    [[ "$(get_os)" == omarchy ]] || fatal 'This script is for Omarchy only'
    command_exists yay || fatal 'yay is not installed. Please install yay first.'

    local aur_list="$DOTFILES_ROOT/packages/aur/packages.txt"
    local line pkg
    local -a packages=()
    if [[ ! -f "$aur_list" ]]; then
        warn "AUR package list not found at $aur_list; skipping AUR installation"
        return 0
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="${line//[[:space:]]/}"
        [[ -z "$line" ]] && continue
        packages+=("$line")
    done < "$aur_list"

    if [[ ${#packages[@]} -eq 0 ]]; then
        info 'No AUR packages to install'
        return 0
    fi

    for pkg in "${packages[@]}"; do
        info "Installing $pkg..."
        yay -S --needed --confirm --diffmenu --editmenu \
            --noanswerdiff --noansweredit -- "$pkg"
    done
    success 'AUR packages installed'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_aur_packages "$@"
fi
