#!/usr/bin/env bash
# Prerequisites layer: Install base tools needed to run everything else
# Linux base implementation
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../shared/detect-os.sh"

if ! is_linux; then
    fatal "This script is for Linux only"
fi

info "Installing prerequisites..."

distro="$(get_os)"

case "$distro" in
    ubuntu)
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y git curl make build-essential
        else
            fatal "apt-get not found"
        fi
        ;;
    fedora)
        if command_exists dnf; then
            sudo dnf install -y git curl make gcc gcc-c++
        else
            fatal "dnf not found"
        fi
        ;;
    arch|omarchy)
        if command_exists pacman; then
            sudo pacman -S --needed --noconfirm git curl make base-devel
        else
            fatal "pacman not found"
        fi
        ;;
    *)
        fatal "Unsupported distribution: $distro"
        ;;
esac

success "Prerequisites installed"
