#!/usr/bin/env bash
# Clone optional workspace repositories without updating existing checkouts.

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

install_repos() {
    command_exists mise || fatal 'mise is not installed. Run make prerequisites first.'
    mise -C "$DOTFILES_ROOT" bootstrap repos apply "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_repos "$@"
fi
