#!/usr/bin/env bash
# Shared by the plugin layer and the Zellij-only compatibility target.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

command_exists curl || fatal "curl is required to install the Zellij plugin"
mkdir -p "$HOME/.config/zellij/plugins"
plugin="$HOME/.config/zellij/plugins/zellij-autolock.wasm"
valid_plugin() {
    [[ -f "$1" && "$(od -An -tx1 -N8 "$1" | tr -d ' \n')" == 0061736d01000000 ]]
}

if [[ -e "$plugin" || -L "$plugin" ]]; then
    valid_plugin "$plugin" || fatal "Existing Zellij plugin is invalid; review it before replacing: $plugin"
    info "zellij-autolock already installed"
else
    info "Downloading zellij-autolock..."
    download="$(mktemp "$HOME/.config/zellij/plugins/.zellij-autolock.XXXXXX")"
    trap 'rm -f "$download"' EXIT
    curl -fSL -o "$download" \
        https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm
    valid_plugin "$download" || fatal "Downloaded Zellij plugin is not a WebAssembly v1 module."
    chmod 644 "$download"
    mv "$download" "$plugin"
    success "zellij-autolock v0.2.2 installed"
fi
