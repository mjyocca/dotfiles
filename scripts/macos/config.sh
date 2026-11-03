#!/usr/bin/env bash
# Config layer: Apply macOS-specific configuration
# macOS implementation
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

if ! is_macos; then
    fatal "This script is for macOS only"
fi

info "Applying macOS configuration..."

# Apply macOS defaults via apply-user-defaults
if command_exists apply-user-defaults; then
    info "Applying system defaults..."
    
    if [[ -f "scripts/macos/defaults.yml" ]]; then
        apply-user-defaults scripts/macos/defaults.yml
    fi
    
    if [[ -f "scripts/macos/defaults.apps.yml" ]]; then
        apply-user-defaults scripts/macos/defaults.apps.yml
    fi
    
    success "macOS defaults applied"
else
    warn "apply-user-defaults not found, skipping macOS defaults"
fi

success "macOS configuration applied"
