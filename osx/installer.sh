#!/usr/bin/env bash

set -o errexit

REPO_URL=https://github.com/mjyocca/dotfiles.git
REPO_PATH="$HOME/dotfiles"

# Color codes
RESET='\033[0m'      # No Color / Reset
GREEN='\033[0;32m'   # Green for Success
YELLOW='\033[0;33m'  # Yellow for Warnings
RED='\033[0;31m'     # Red for Errors
BLUE='\033[0;34m'    # Blue for Logs

# Logging Functions
info() {
  printf "${BLUE}[INFO] %s${RESET}\n" "$1"
}

warn() {
  printf "${YELLOW}[WARN] %s${RESET}\n" "$1"
}

error() {
  printf "${RED}[ERROR] %s${RESET}\n" "$1"
}

success() {
  printf "${GREEN}[SUCCESS] %s${RESET}\n" "$1"
}

install_xcode() {
	if xcode-select -p >/dev/null; then
		warn "xCode Command Line Tools already installed"
	else
		info "Installing xCode Command Line Tools..."
		xcode-select --install
		sudo xcodebuild -license accept
	fi
}

install_homebrew() {
	export HOMEBREW_CASK_OPTS="--appdir=/Applications"
	if hash brew &>/dev/null; then
		warn "Homebrew already installed"
	else
		info "Installing homebrew..."
		sudo --validate # reset `sudo` timeout to use Homebrew install in noninteractive mode
		NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	fi
}

# Check if the script is being run directly or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	info "### DOTFILES ###"
	info "Bootstraping..."

	install_xcode
	install_homebrew

	info "Installing Git..."
	brew install git

	info "Cloning repo $REPO_URL into $REPO_PATH"
	git clone "$REPO_URL" "$REPO_PATH"

	info "Change path to $REPO_PATH"
	cd "$REPO_PATH" >/dev/null

	info "Installing dependencies..."
	make bootstrap_osx
fi