#!/usr/bin/env bash
# Stow dotfile packages into $HOME via GNU Stow.
#
# Usage:
#   ./scripts/stow.sh              # stow all packages (respects ignore file)
#   ./scripts/stow.sh <pkg>        # stow a single named package
#   ./scripts/stow.sh <p1> <p2>    # stow several named packages
#
# Per-machine ignore file:
#   .stow-ignore.local  (git-ignored, lives at the repo root)
#
#   List one package name per line. Blank lines and lines starting with
#   '#' are ignored. Packages listed here are skipped during a full stow.
#   Single-package invocations bypass the ignore list entirely.
#
# Example .stow-ignore.local:
#   # work machine — use corporate zsh config instead
#   zsh
#   homebrew

set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=utils.sh
source "${DOTFILES_ROOT}/scripts/utils.sh"

IGNORE_FILE="${DOTFILES_ROOT}/.stow-ignore.local"

# ── Load ignore list ───────────────────────────────────────────────────────
_load_ignore_list() {
  local -n _ref=$1   # nameref: caller passes the name of their array
  if [[ ! -f "$IGNORE_FILE" ]]; then
    return
  fi
  while IFS= read -r line; do
    # Strip leading/trailing whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    # Skip blanks and comments
    [[ -z "$line" || "$line" == \#* ]] && continue
    _ref+=("$line")
  done < "$IGNORE_FILE"
}

# ── Stow a list of package names ──────────────────────────────────────────
_stow_packages() {
  local packages=("$@")
  if [[ ${#packages[@]} -eq 0 ]]; then
    warn "No packages to stow."
    return
  fi
  info "Stowing: ${packages[*]}"
  stow --dir "${DOTFILES_ROOT}/packages" \
       --target "$HOME" \
       --verbose 2 \
       "${packages[@]}"
}

# ── Main ──────────────────────────────────────────────────────────────────
stow_dotfiles() {
  # If package names were passed as arguments, stow only those (no ignore list)
  if [[ $# -gt 0 ]]; then
    for pkg in "$@"; do
      if [[ ! -d "${DOTFILES_ROOT}/packages/${pkg}" ]]; then
        error "Package not found: packages/${pkg}"
        exit 1
      fi
    done
    _stow_packages "$@"
    success "Done."
    return
  fi

  # No arguments — stow everything, minus the ignore list
  local -a ignore=()
  _load_ignore_list ignore

  if [[ ${#ignore[@]} -gt 0 ]]; then
    info "Ignoring packages (from .stow-ignore.local): ${ignore[*]}"
  fi

  # Collect all packages, filtering out ignored ones
  local -a to_stow=()
  for pkg_dir in "${DOTFILES_ROOT}/packages"/*/; do
    pkg="$(basename "$pkg_dir")"
    skip=0
    for ignored in "${ignore[@]}"; do
      if [[ "$pkg" == "$ignored" ]]; then
        skip=1
        break
      fi
    done
    if [[ $skip -eq 0 ]]; then
      to_stow+=("$pkg")
    else
      warn "Skipping:  $pkg"
    fi
  done

  _stow_packages "${to_stow[@]}"
  success "Done."
}

# Run directly or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  stow_dotfiles "$@"
fi
