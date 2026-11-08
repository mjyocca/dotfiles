#!/usr/bin/env bash
# Apple Silicon macOS prerequisite interface.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../shared/install-mise.sh"

# Subshell keeps the temporary installer and its EXIT trap local to this stage.
install_prerequisites() (
    is_macos || fatal 'This script is for macOS only'
    info 'Installing prerequisites...'

    if ! xcode-select -p &>/dev/null; then
        xcode-select --install
        fatal 'Complete Command Line Tools installation in the GUI, then rerun make bootstrap.'
    fi

    # Fresh macOS must be able to install mise before Homebrew exists.
    install_mise

    if ! command_exists brew; then
        info 'Installing Homebrew...'
        installer="$(mktemp "${TMPDIR:-/tmp}/homebrew-installer.XXXXXX")"
        trap 'rm -f "$installer"' EXIT
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"
        /bin/bash "$installer"
    else
        info 'Homebrew already installed'
    fi

    # CLT supplies git and make; packages installs the tracked replacements.
    command_exists brew || fatal 'Homebrew installation did not provide brew; expected /opt/homebrew/bin/brew.'
    for dependency in git curl make; do
        command_exists "$dependency" || fatal "$dependency is required before package bootstrap."
    done
    success 'Prerequisites installed'
)

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_prerequisites "$@"
fi
