#!/usr/bin/env bash

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
