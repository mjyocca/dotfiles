#!/usr/bin/env bash
# Upgrade effective mise tools without changing requests or removing old versions.

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

upgrade_tools() {
    (($# == 0)) || fatal 'Tool upgrades accept no arguments; use mise directly for scoped upgrades.'
    command_exists mise || fatal 'mise is not installed. Run make prerequisites first.'
    info 'Upgrading effective mise tools within configured version ranges...'
    mise -C "$DOTFILES_ROOT" upgrade --no-prune
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    upgrade_tools "$@"
fi
