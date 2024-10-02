#!/usr/bin/env bash

set -o errexit

. $PWD/scripts/utils.sh

tmux_plugin_manager() {
  info "Installing tmux plugin manager..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
}

# Check if the script is being run directly or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Script is being run directly, so call the function
  tmux_plugin_manager
fi