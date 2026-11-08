#!/usr/bin/env bash
# Linux package interface; distributions may source and override install_packages.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/packages.sh"

install_packages() {
    is_linux || fatal 'This script is for Linux only'
    install_system_packages "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_packages "$@"
fi
