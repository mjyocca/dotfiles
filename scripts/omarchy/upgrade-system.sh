#!/usr/bin/env bash
# Delegate full-system upgrades to Omarchy, including its prompts and migrations.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../shared/detect-os.sh"

upgrade_system() {
    local answer
    is_linux || fatal 'This script is for Linux only'
    [[ "$(get_os)" == omarchy ]] || fatal 'This script is for Omarchy only'
    (($# == 0)) || fatal 'Omarchy system upgrades accept no arguments.'
    command_exists omarchy-update || fatal 'The official omarchy-update command is required; no Pacman fallback is provided.'
    [[ -t 0 && -t 1 ]] || fatal 'Omarchy system upgrades require an interactive terminal.'

    warn 'This updates the whole Omarchy system, not just tracked packages.'
    warn 'Omarchy handles snapshots, migrations, AUR updates, and orphan cleanup, and may prompt for a reboot.'
    printf 'Continue to the official Omarchy updater? [y/N] '
    if ! IFS= read -r answer; then
        info 'System upgrade cancelled.'
        return 1
    fi
    case "$answer" in
        y|Y|yes|YES) omarchy-update ;;
        *) info 'System upgrade cancelled.'; return 1 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    upgrade_system "$@"
fi
