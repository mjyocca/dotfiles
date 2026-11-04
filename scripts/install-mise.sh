#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/shared/environment.sh"

# macOS must be able to install mise before Homebrew exists.
# Preserve any existing provider, including Homebrew's mise and Omarchy's mise-bin.
verify_mise() {
    mise --version
    if ! mise bootstrap --help >/dev/null 2>&1 || ! mise dotfiles apply --help >/dev/null 2>&1; then
        echo 'Error: installed mise lacks required bootstrap/dotfiles commands. Update it with its existing provider.' >&2
        exit 1
    fi
}

if command -v mise &> /dev/null; then
    echo '✓ mise is already installed; preserving its provider'
    verify_mise
    exit 0
fi

echo "Installing mise..."

case "$(uname -s)" in
    Darwin)
        if [[ -e "$HOME/.local/bin/mise" || -L "$HOME/.local/bin/mise" ]]; then
            echo 'Error: existing ~/.local/bin/mise is not executable; review it before installing.' >&2
            exit 1
        fi
        installer="$(mktemp "${TMPDIR:-/tmp}/mise-installer.XXXXXX")"
        trap 'rm -f "$installer"' EXIT
        curl -fsSL https://mise.run -o "$installer"
        MISE_INSTALL_PATH="$HOME/.local/bin/mise" MISE_INSTALL_HELP=0 /bin/sh "$installer"
        ;;
    Linux)
        # Linux - detect package manager
        if command -v pacman &> /dev/null; then
            # Omarchy/Arch - use pacman
            sudo pacman -S --needed --noconfirm mise
        else
            echo "Error: Unsupported Linux package manager"
            echo "mise must be installed via package manager (pacman for Omarchy/Arch)"
            exit 1
        fi
        ;;
    *)
        echo "Error: Unsupported platform $(uname -s)"
        exit 1
        ;;
esac

# Verify installation
if command -v mise &> /dev/null; then
    echo '✓ mise installed successfully'
    verify_mise
else
    echo "Error: mise installation failed"
    exit 1
fi
