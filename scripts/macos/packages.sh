#!/usr/bin/env bash
# Packages layer: Install system packages via mise bootstrap
# macOS implementation
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

if ! is_macos; then
    fatal "This script is for macOS only"
fi

info "Installing system packages via mise bootstrap..."

if ! command_exists mise; then
    fatal "mise is not installed. Run prerequisites first."
fi

mise bootstrap

success "System packages installed"
