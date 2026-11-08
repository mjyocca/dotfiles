#!/usr/bin/env bash
# Shared initialization and functions; safe to source through multiple layers.

if [[ "${DOTFILES_UTILS_LOADED:-}" == 1 ]]; then
    return 0
fi
readonly DOTFILES_UTILS_LOADED=1

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/environment.sh"
readonly DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Colors
readonly RESET='\033[0m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'

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

# Check if running on macOS
is_macos() {
    [[ "$(uname -s)" == "Darwin" ]]
}

# Check if running on Linux
is_linux() {
    [[ "$(uname -s)" == "Linux" ]]
}
