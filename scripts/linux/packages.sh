#!/usr/bin/env bash
# Packages layer: Install system packages via mise bootstrap
# Linux base implementation
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

if ! is_linux; then
    fatal "This script is for Linux only"
fi

info "Installing system packages via mise bootstrap..."

if ! command_exists mise; then
    fatal "mise is not installed. Run prerequisites first."
fi

# Tool installation is isolated in the tools layer to preserve asdf ownership.
mise bootstrap --skip tools

success "System packages installed"
