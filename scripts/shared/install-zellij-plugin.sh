#!/usr/bin/env bash
# Shared by the plugin layer and the Zellij-only compatibility target.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

command_exists curl || fatal "curl is required to install the Zellij plugin"
mkdir -p "$HOME/.config/zellij/plugins"
plugin="$HOME/.config/zellij/plugins/zellij-autolock.wasm"
if [[ ! -f "$plugin" ]]; then
    info "Downloading zellij-autolock..."
    curl -fSL -o "$plugin" \
        https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm
    success "zellij-autolock v0.2.2 installed"
else
    info "zellij-autolock already installed"
fi
