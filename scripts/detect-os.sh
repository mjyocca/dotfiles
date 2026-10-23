#!/usr/bin/env bash
# Detect OS and select appropriate dotfiles profile.
#
# Source this file, then use $DOTFILES_PROFILE to choose which profile to stow.
# Can be overridden via PROFILE env var or command-line arg.
#
# Sets:
#   DOTFILES_OS      - "Darwin" | "Linux" | "Windows"
#   DOTFILES_DISTRO  - "macos" | "omarchy" | "arch" | "ubuntu" | etc.
#   DOTFILES_PROFILE - "macos" | "omarchy" (primary selection key)
#
# Detection logic:
#   - macOS → "macos"
#   - Linux with ID=omarchy or ID_LIKE contains "arch" → "omarchy"
#   - Other Linux → use $ID (ubuntu, fedora, etc.)
#
# Override:
#   PROFILE=linux ./scripts/stow.sh        # force profile
#   ./scripts/detect-os.sh linux           # arg override

set -euo pipefail

# shellcheck source=utils.sh
source "${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/scripts/utils.sh"

# Allow override via PROFILE env or first arg
if [[ -n "${PROFILE:-}" ]]; then
  DOTFILES_PROFILE="$PROFILE"
elif [[ $# -gt 0 && "$1" != "-"* ]]; then
  DOTFILES_PROFILE="$1"
else
  # Auto-detect
  case "$(uname -s)" in
    Darwin)
      DOTFILES_OS="Darwin"
      DOTFILES_PROFILE="macos"
      ;;
    Linux)
      DOTFILES_OS="Linux"
      if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        DOTFILES_DISTRO="${ID:-unknown}"
        
        # Omarchy detection: explicit ID or ID_LIKE contains "arch"
        if [[ "${ID:-}" == "omarchy" || "${ID_LIKE:-}" == *"arch"* ]]; then
          DOTFILES_PROFILE="omarchy"
        else
          DOTFILES_PROFILE="${DOTFILES_DISTRO}"
        fi
      else
        DOTFILES_DISTRO="linux"
        DOTFILES_PROFILE="linux"
      fi
      ;;
    CYGWIN*|MINGW*|MSYS*)
      DOTFILES_OS="Windows"
      DOTFILES_PROFILE="windows"
      ;;
    *)
      DOTFILES_OS="Unknown"
      DOTFILES_PROFILE="unknown"
      ;;
  esac
fi

# Export for subprocesses
export DOTFILES_OS DOTFILES_PROFILE

# Verify profile exists (if called standalone, not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ "${1:-}" == "--print" ]]; then
    # Machine-readable output for Makefile integration
    printf '%s\n' "$DOTFILES_PROFILE"
    exit 0
  fi
  info "Detected: OS=${DOTFILES_OS:-unknown}, Profile=$DOTFILES_PROFILE"
  PROFILE_FILE="${DOTFILES_ROOT:-.}/profiles/${DOTFILES_PROFILE}"
  if [[ -f "$PROFILE_FILE" ]]; then
    success "Profile exists: $PROFILE_FILE"
  else
    warn "No profile found: $PROFILE_FILE"
    warn "Available profiles:"
    ls -1 "${DOTFILES_ROOT:-.}/profiles" 2>/dev/null | sed 's/^/  /' || echo "  (no profiles/ directory)"
  fi
fi
