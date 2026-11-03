#!/usr/bin/env bash
# Shared utility functions for all scripts
# Source this at the top of other scripts: source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

set -euo pipefail

# Colors
readonly RESET='\033[0m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'

# Logging functions
info() {
    printf "${BLUE}[INFO]${RESET} %s\n" "$*"
}

success() {
    printf "${GREEN}[SUCCESS]${RESET} %s\n" "$*"
}

warn() {
    printf "${YELLOW}[WARN]${RESET} %s\n" "$*"
}

error() {
    printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2
}

fatal() {
    printf "${RED}[FATAL]${RESET} %s\n" "$*" >&2
    exit 1
}

# Check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Get the directory of the current script
script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# Get the repository root (assumes scripts are in scripts/ subdirectory)
repo_root() {
    local script_path
    script_path="$(script_dir)"
    # If we're in scripts/shared/, go up 2 levels
    if [[ "$script_path" == *"/scripts/shared" ]]; then
        cd "$script_path/../.." && pwd
    # If we're in scripts/linux/, scripts/macos/, etc., go up 2 levels
    elif [[ "$script_path" == *"/scripts/"* ]]; then
        cd "$script_path/.." && pwd
    else
        echo "$script_path"
    fi
}

# Check if running on macOS
is_macos() {
    [[ "$(uname -s)" == "Darwin" ]]
}

# Check if running on Linux
is_linux() {
    [[ "$(uname -s)" == "Linux" ]]
}

# Get the distribution name
get_distro() {
    if is_macos; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "${ID:-unknown}"
    else
        echo "unknown"
    fi
}

# Check if distro is Arch-based
is_arch_based() {
    local distro
    distro="$(get_distro)"
    [[ "$distro" == "arch" || "$distro" == "omarchy" ]]
}

# Prompt for confirmation (default: yes)
confirm() {
    local prompt="${1:-Continue?}"
    local response
    
    read -rp "$prompt [Y/n] " response
    case "$response" in
        [nN]|[nN][oO])
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}
