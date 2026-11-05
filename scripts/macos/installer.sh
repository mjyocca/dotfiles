#!/usr/bin/env bash

set -o errexit

REPO_URL=https://github.com/mjyocca/dotfiles.git
REPO_PATH="$HOME/dotfiles"

# Logging is inline so this installer can run before the repository is cloned.
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
		error "Complete Command Line Tools installation, then rerun this installer."
		exit 1
	fi
}

# Idempotent repository handling
clone_or_update_repo() {
	if [[ -d "$REPO_PATH" ]]; then
		info "Repository already exists at $REPO_PATH"
		cd "$REPO_PATH"
		
		# Check if it's a git repository
		if git rev-parse --git-dir > /dev/null 2>&1; then
			info "Updating existing repository..."
			git pull --ff-only || { error "Repository update failed; bootstrap stopped."; exit 1; }
		else
			warn "$REPO_PATH exists but is not a git repository"
			warn "Please remove it manually and re-run this script"
			exit 1
		fi
	else
		info "Cloning repo $REPO_URL into $REPO_PATH"
		git clone "$REPO_URL" "$REPO_PATH"
		cd "$REPO_PATH"
	fi
}

# Check if the script is being run directly or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	info "### DOTFILES ###"
	info "bootstrapping..."

	install_xcode

	# Command Line Tools supplies git for cloning; bootstrap installs mise before Homebrew.
	clone_or_update_repo

	info "Installing dependencies..."
	make bootstrap PROFILE=macos
fi
