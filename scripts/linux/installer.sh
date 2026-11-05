#!/usr/bin/env bash
# Installer: Fresh Linux install entry point
# Linux base implementation
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

if ! is_linux; then
    fatal "This script is for Linux only"
fi

info "=== Linux Fresh Install ==="

# Step 1: Install prerequisites
info "Step 1: Installing prerequisites..."
bash "$(dirname "${BASH_SOURCE[0]}")/prerequisites.sh"

# Step 2: Clone dotfiles repo (if not already in it)
info "Step 2: Setting up dotfiles..."
if [[ -d "$HOME/dotfiles" ]]; then
    info "Dotfiles directory already exists at $HOME/dotfiles"
else
    warn "Please clone your dotfiles repository to $HOME/dotfiles"
    warn "Then run: make bootstrap"
    exit 1
fi

# Step 3: Bootstrap
info "Step 3: Bootstrapping system..."
cd "$HOME/dotfiles"
make bootstrap

success "=== Linux Fresh Install Complete ==="
