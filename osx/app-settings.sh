#!/usr/bin/env bash

. $PWD/scripts/utils.sh

vscode_settings() {
	defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false 	
}

# Check if the script is being run directly or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# Script is being run directly, so call the function
	vscode_settings
fi