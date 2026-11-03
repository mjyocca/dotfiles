#!/usr/bin/env bash
# Tools layer: Install dev tools via mise tool versions
# macOS implementation
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

if ! is_macos; then
    fatal "This script is for macOS only"
fi

info "Installing dev tools via mise..."

if ! command_exists mise; then
    fatal "mise is not installed. Run prerequisites first."
fi

mise install

success "Dev tools installed"
