#!/usr/bin/env bash
# Deploy dotfiles, including the global mise tool fragments and discovery policy.

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

deploy_dotfiles() {
    command_exists mise || fatal 'mise is not installed. Run make prerequisites first.'
    mise -C "$DOTFILES_ROOT" dotfiles apply "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    deploy_dotfiles "$@"
fi
