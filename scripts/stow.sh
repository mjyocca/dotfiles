#!/usr/bin/env bash

. $PWD/scripts/utils.sh

stow_dotfiles() {
	local to_stow="$(find stow -maxdepth 1 -type d -mindepth 1 | awk -F "/" '{print $NF}' ORS=' ')"
	info "Stowing: $to_stow"
	stow --dir stow --verbose 2 --target "$HOME" $to_stow
}

# Check if the script is being run directly or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# Script is being run directly, so call the function
	stow_dotfiles
fi