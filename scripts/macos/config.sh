#!/usr/bin/env bash
# Config layer: Apply macOS-specific configuration
# macOS implementation
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

if ! is_macos; then
    fatal "This script is for macOS only"
fi

info "Applying macOS configuration..."

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
config_dir="$repo_root/.config/macos"

# Apply macOS defaults via apply-user-defaults
if command_exists apply-user-defaults; then
    info "Applying system defaults..."

    applied=false
    for defaults_file in "$config_dir/defaults.yml" "$config_dir/defaults.apps.yml"; do
        if [[ -f "$defaults_file" ]]; then
            apply-user-defaults "$defaults_file"
            applied=true
        else
            warn "Defaults file not found: $defaults_file"
        fi
    done

    if [[ "$applied" == true ]]; then
        success "macOS defaults applied"
    else
        warn "No macOS defaults files found, skipping defaults"
    fi
else
    warn "apply-user-defaults not found, skipping macOS defaults"
fi

info "macOS configuration step complete"
