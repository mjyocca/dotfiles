#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# macOS must be able to install mise before Homebrew exists.
# Preserve any existing provider, including Homebrew's mise and Omarchy's mise-bin.
verify_mise() {
    mise --version
    if ! mise bootstrap --help >/dev/null 2>&1 || ! mise dotfiles apply --help >/dev/null 2>&1; then
        echo 'Error: installed mise lacks required bootstrap/dotfiles commands. Update it with its existing provider.' >&2
        exit 1
    fi
}

install_mise() (
    if command_exists mise; then
        info 'mise is already installed; preserving its provider'
        verify_mise
        exit 0
    fi

    info 'Installing mise...'
    case "$(uname -s)" in
        Darwin)
            if [[ -e "$HOME/.local/bin/mise" || -L "$HOME/.local/bin/mise" ]]; then
                fatal 'Existing ~/.local/bin/mise is not executable; review it before installing.'
            fi
            installer="$(mktemp "${TMPDIR:-/tmp}/mise-installer.XXXXXX")"
            trap 'rm -f "$installer"' EXIT
            curl -fsSL https://mise.run -o "$installer"
            MISE_INSTALL_PATH="$HOME/.local/bin/mise" MISE_INSTALL_HELP=0 /bin/sh "$installer"
            ;;
        Linux)
            if command_exists pacman; then
                sudo pacman -S --needed --noconfirm mise
            else
                fatal 'Install mise with a supported provider before bootstrapping this distribution.'
            fi
            ;;
        *)
            fatal "Unsupported platform $(uname -s)"
            ;;
    esac

    command_exists mise || fatal 'mise installation failed'
    verify_mise
    success 'mise installed successfully'
)

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_mise "$@"
fi
