#!/usr/bin/env bash

set -o errexit

REPO_URL=https://github.com/mjyocca/dotfiles.git
REPO_PATH="$HOME/dotfiles"

# Color codes
RESET='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'

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

# Check prerequisites
check_prerequisites() {
	info "Checking prerequisites..."
	
	local missing=()
	
	if ! command -v git >/dev/null 2>&1; then
		missing+=("git")
	fi
	
	if ! command -v curl >/dev/null 2>&1; then
		missing+=("curl")
	fi
	
	if ! command -v make >/dev/null 2>&1; then
		missing+=("make")
	fi
	
	if [[ ${#missing[@]} -gt 0 ]]; then
		error "Missing prerequisites: ${missing[*]}"
		error "Omarchy should have these pre-installed via base-devel"
		error "Please install them first: sudo pacman -S ${missing[*]}"
		exit 1
	fi
	
	success "All prerequisites present"
}

# Idempotent repository handling
clone_or_update_repo() {
	if [[ -d "$REPO_PATH" ]]; then
		info "Repository already exists at $REPO_PATH"
		cd "$REPO_PATH"
		
		if git rev-parse --git-dir > /dev/null 2>&1; then
			info "Updating existing repository..."
			git pull --ff-only || warn "Failed to update repository (continuing anyway)"
		else
			error "$REPO_PATH exists but is not a git repository"
			error "Please remove it manually and re-run this script"
			exit 1
		fi
	else
		info "Cloning repo $REPO_URL into $REPO_PATH"
		git clone "$REPO_URL" "$REPO_PATH"
		cd "$REPO_PATH"
	fi
}

# Main installation flow
main() {
	info "### DOTFILES ###"
	info "Omarchy bootstrap starting..."
	
	check_prerequisites
	clone_or_update_repo
	
	info "Running bootstrap..."
	make bootstrap_linux
	
	success "Bootstrap complete!"
	info "You may need to restart your shell or run: source ~/.zshrc"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
