#!/usr/bin/env bash
# Shared package implementation; platform entrypoints can extend or replace it.

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

install_system_packages() {
    command_exists mise || fatal 'mise is not installed. Run make prerequisites first.'
    info 'Installing system packages (without deploying dotfiles)...'
    mise -C "$DOTFILES_ROOT" bootstrap --only packages "$@"
    success 'System packages installed'
}
