#!/usr/bin/env bash
# Packages layer: Install system packages
# Omarchy implementation (calls Linux packages + AUR)
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

source "$(dirname "${BASH_SOURCE[0]}")/../shared/detect-os.sh"

if [[ "$(get_os)" != "omarchy" ]]; then
    fatal "This script is for Omarchy only"
fi

info "Installing Omarchy packages..."

# Step 1: Install base Linux packages via mise bootstrap
bash "$(dirname "${BASH_SOURCE[0]}")/../linux/packages.sh"

# Step 2: Install AUR packages
bash "$(dirname "${BASH_SOURCE[0]}")/aur.sh"

success "Omarchy packages installed"
