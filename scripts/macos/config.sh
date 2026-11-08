#!/usr/bin/env bash
# Config layer: Apply macOS-specific configuration
# macOS implementation
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

configure_platform() {
    is_macos || fatal 'This script is for macOS only'
    command_exists mise || fatal 'mise is not installed. Run make prerequisites first.'
    info 'Applying macOS preferences...'
    # Preferences only: no package installation or LaunchAgent activation.
    mise -C "$DOTFILES_ROOT" -E macos bootstrap macos defaults apply "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    configure_platform "$@"
fi
