#!/usr/bin/env bash
# Plugins layer: Install editor/shell plugins
# Linux base implementation
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

info "Installing plugins..."

# Zellij plugins
mkdir -p "${HOME}/.config/zellij/plugins"

# Download zellij-autolock plugin if not already present
if [[ ! -f "${HOME}/.config/zellij/plugins/zellij-autolock.wasm" ]]; then
    info "Downloading zellij-autolock..."
    curl -fSL -o "${HOME}/.config/zellij/plugins/zellij-autolock.wasm" \
        https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm
    success "zellij-autolock v0.2.2 installed"
else
    info "zellij-autolock already installed"
fi

success "Plugins installed"
