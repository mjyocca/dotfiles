#!/usr/bin/env bash

setup_osx() {
  echo "Configuring MacOS default settings"

 	# Show hidden files inside the finder
	defaults write com.apple.finder "AppleShowAllFiles" -bool true

  echo "Enabling ssh agent on setup"
  cp "$HOME/dotfiles/osx/com.openssh.ssh-agent.plist" "$HOME/Library/LaunchAgents/"
  launchctl load "$HOME/Library/LaunchAgents/com.openssh.ssh-agent.plist"
  launchctl enable gui/$(id -u)/com.openssh.ssh-agent
}

setup_osx
