#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/shared/utils.sh"

setup_github_ssh() {
    if [[ "${SSH_PASSPHRASE+x}" == x ]]; then
        fatal "Unset SSH_PASSPHRASE; enter the passphrase interactively when ssh-keygen prompts."
    fi

    local key_path="$HOME/.ssh/id_ed25519"
    if [[ -e "$key_path" || -L "$key_path" || -e "$key_path.pub" || -L "$key_path.pub" ]]; then
        fatal "SSH key files already exist at $key_path; leaving them untouched."
    fi

    command_exists ssh-keygen || fatal "ssh-keygen is required"
    command_exists ssh-add || fatal "ssh-add is required"

    info "Generating an SSH key; enter a passphrase at the secure prompt."
    (
        umask 077
        mkdir -p "$HOME/.ssh"
        ssh-keygen -t ed25519 -f "$key_path" -C ""
    )

    info "Adding the SSH key to your agent"
    if is_macos; then
        ssh-add --apple-use-keychain "$key_path"
    else
        ssh-add "$key_path"
    fi

    info "Add the public key at $key_path.pub to your GitHub account."
}

# Check if the script is being run directly or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# Script is being run directly, so call the function
	setup_github_ssh
fi
