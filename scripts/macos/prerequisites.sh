#!/usr/bin/env bash
# Prerequisites layer: Install base tools needed to run everything else
# macOS implementation
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

if ! is_macos; then
    fatal "This script is for macOS only"
fi

info "Installing prerequisites..."

# Install Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
    info "Installing Xcode Command Line Tools..."
    xcode-select --install
    info "Please complete Xcode CLT installation in the GUI prompt"
else
    info "Xcode Command Line Tools already installed"
fi

# Install Homebrew if not present
if ! command_exists brew; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    info "Homebrew already installed"
fi

# Install git via Homebrew
if ! command_exists git; then
    info "Installing git..."
    brew install git
fi

bash "$(dirname "${BASH_SOURCE[0]}")/../install-mise.sh"

success "Prerequisites installed"
