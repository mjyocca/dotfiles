#!/usr/bin/env bash
# Install normal effective mise requests, only after global configuration exists.

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

install_tools() {
    local config_dir="${MISE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mise}"
    local file
    for file in conf.d/10-dotfiles-tools.toml conf.d/20-dotfiles-platform.toml miserc.toml; do
        if [[ ! -e "$config_dir/$file" ]]; then
            fatal "Missing $config_dir/$file; inspect and deploy with make link first."
        fi
    done
    command_exists mise || fatal 'mise is not installed. Run make prerequisites first.'
    mise -C "$DOTFILES_ROOT" install "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_tools "$@"
fi
