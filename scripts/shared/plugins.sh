#!/usr/bin/env bash
# Shared plugin implementation. Platform scripts can extend install_plugins.

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

install_plugins() {
    local dependency gh_binary installed_gh_extensions runtime_manager
    info 'Installing plugins...'
    for dependency in git mise curl; do
        command_exists "$dependency" || fatal "$dependency is required; run the packages/tools layers first."
    done

    # Use native merged checkout vars, not an inherited interactive-shell value.
    runtime_manager="$(mise -C "$DOTFILES_ROOT" vars dotfiles_runtime_manager)"
    case "$runtime_manager" in
        asdf|mise) ;;
        *) fatal 'dotfiles_runtime_manager must be asdf or mise' ;;
    esac

    # Lookup installed tools without activating runtimes or relying on shell PATH.
    gh_binary="$(mise -C "$DOTFILES_ROOT" which gh --tool gh)"

    # Install TPM itself; installing/updating individual tmux plugins stays explicit.
    if [[ ! -e "$HOME/.tmux/plugins/tpm" && ! -L "$HOME/.tmux/plugins/tpm" ]]; then
        mkdir -p "$HOME/.tmux/plugins"
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    fi

    if [[ "$runtime_manager" == asdf ]]; then
        bash "$DOTFILES_ROOT/scripts/shared/install-asdf-plugins.sh"
    fi

    installed_gh_extensions="$("$gh_binary" extension list)"
    if ! grep -Eq '(^|[[:space:]])dlvhdr/gh-dash([[:space:]]|$)' <<< "$installed_gh_extensions"; then
        "$gh_binary" extension install dlvhdr/gh-dash
    fi

    bash "$DOTFILES_ROOT/scripts/shared/install-zellij-plugin.sh"
    success 'Plugins installed'
}
