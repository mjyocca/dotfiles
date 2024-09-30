#!/usr/bin/env bash

set -o errexit

. $PWD/scripts/utils.sh
. $PWD/osx/installer.sh

# Check if the script is being run directly or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Script is being run directly, so call the function
	install_xcode
	install_homebrew
fi