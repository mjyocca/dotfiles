#!/usr/bin/env bash
# Linux prerequisite interface; distributions can override install_prerequisites.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../shared/detect-os.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../shared/install-mise.sh"

install_prerequisites() {
    is_linux || fatal 'This script is for Linux only'
    info 'Installing prerequisites...'

    case "$(get_os)" in
        ubuntu)
            command_exists apt-get || fatal 'apt-get not found'
            sudo apt-get update
            sudo apt-get install -y git curl make build-essential
            ;;
        fedora)
            command_exists dnf || fatal 'dnf not found'
            sudo dnf install -y git curl make gcc gcc-c++
            ;;
        arch|omarchy)
            command_exists pacman || fatal 'pacman not found'
            sudo pacman -S --needed --noconfirm git curl make base-devel
            ;;
        *)
            fatal "No Linux prerequisites implemented for $(get_os)"
            ;;
    esac

    # A new distribution also needs an appropriate mise provider here or upstream.
    install_mise
    success 'Prerequisites installed'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_prerequisites "$@"
fi
