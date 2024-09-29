#!/usr/bin/env bash

. $PWD/scripts/utils.sh

setup_osx() {
  info "Configuring MacOS default settings"

 	# Show hidden files inside the finder
	defaults write com.apple.finder "AppleShowAllFiles" -bool true

  info "Enabling ssh agent on setup"
  cp "$HOME/dotfiles/osx/com.openssh.ssh-agent.plist" "$HOME/Library/LaunchAgents/"
  launchctl unload "$HOME/Library/LaunchAgents/com.openssh.ssh-agent.plist"
  launchctl load "$HOME/Library/LaunchAgents/com.openssh.ssh-agent.plist"
  launchctl enable gui/$(id -u)/com.openssh.ssh-agent
}

# Check if the script is being run directly or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Script is being run directly, so call the function
  setup_osx
fi