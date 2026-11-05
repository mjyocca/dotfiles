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
if ! command_exists mise; then
    fatal "mise is not installed. Run prerequisites first."
fi

# Scope to preferences only; do not install packages or load LaunchAgents.
mise -C "$repo_root" -E macos bootstrap macos defaults apply "$@"

info "macOS configuration step complete"
