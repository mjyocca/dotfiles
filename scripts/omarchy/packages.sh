#!/usr/bin/env bash
# Extend shared package installation with Omarchy's interactive AUR stage.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../linux/packages.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../shared/detect-os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/aur.sh"

install_packages() {
    is_linux || fatal 'This script is for Linux only'
    [[ "$(get_os)" == omarchy ]] || fatal 'This script is for Omarchy only'
    # Native mise flags cannot safely describe the separate interactive AUR step.
    # In particular, never preview system packages then actually install AUR ones.
    (($# == 0)) || fatal 'Omarchy packages accepts no arguments; preview system packages with mise bootstrap --only packages --dry-run and review AUR separately.'
    install_system_packages
    install_aur_packages
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_packages "$@"
fi
