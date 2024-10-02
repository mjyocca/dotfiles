#!/usr/bin/env bash

set -o errexit

. $PWD/scripts/utils.sh

tmux_plugin_manager() {
  info "Installing tmux plugin manager..."
  if [ -d ~/.tmux/plugins/tpm ]; then
    warn "tmux plugin manager already installed"
  else
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi 
}

asdf_plugins() {
  info "Installing asdf plugins..."
  if asdf version >/dev/null; then
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
    asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
    asdf plugin add golang https://github.com/asdf-community/asdf-golang.git
    asdf plugin-add rust https://github.com/asdf-community/asdf-rust.git
  else
    error "asdf is not installed"
  fi
}

# Check if the script is being run directly or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Script is being run directly, so call the function
  tmux_plugin_manager
  asdf_plugins
fi