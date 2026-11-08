#!/usr/bin/env bash
# macOS package interface.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/packages.sh"

install_packages() {
    is_macos || fatal 'This script is for macOS only'
    install_system_packages "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_packages "$@"
fi
