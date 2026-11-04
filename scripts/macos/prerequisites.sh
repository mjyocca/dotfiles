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
    fatal "Complete Command Line Tools installation in the GUI, then rerun this command."
else
    info "Xcode Command Line Tools already installed"
fi

# Install/reuse mise first; fresh macOS does not require Homebrew for this step.
bash "$(dirname "${BASH_SOURCE[0]}")/../install-mise.sh"

# Install Homebrew if not present (Apple Silicon prefix is on provisioning PATH).
if ! command_exists brew; then
    info "Installing Homebrew..."
    installer="$(mktemp "${TMPDIR:-/tmp}/homebrew-installer.XXXXXX")"
    trap 'rm -f "$installer"' EXIT
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"
    /bin/bash "$installer"
else
    info "Homebrew already installed"
fi

# CLT supplies git and make; the packages layer installs tracked replacements via mise.
command_exists brew || fatal "Homebrew installation did not provide brew; expected /opt/homebrew/bin/brew."
for dependency in git curl make; do
    command_exists "$dependency" || fatal "$dependency is required before package bootstrap."
done

success "Prerequisites installed"
