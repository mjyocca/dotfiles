#!/usr/bin/env bash
# Upgrade configured macOS system packages through mise, not every Brew package.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

upgrade_system() {
    is_macos || fatal 'This script is for macOS only'
    (($# == 0)) || fatal 'System upgrades accept no arguments; use mise directly for scoped upgrades.'
    command_exists mise || fatal 'mise is not installed. Run make prerequisites first.'
    info 'Upgrading installed system packages declared in the effective mise configuration...'
    mise -C "$DOTFILES_ROOT" bootstrap packages upgrade
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    upgrade_system "$@"
fi
