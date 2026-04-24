#!/usr/bin/env bash
# Stow dotfile packages into $HOME via GNU Stow.
#
# Usage:
#   ./scripts/stow.sh                        # stow all packages (respects ignore file)
#   ./scripts/stow.sh <pkg> [<pkg> ...]      # stow specific packages
#   ./scripts/stow.sh --adopt <pkg>          # pass extra flags to stow before pkg names
#   ./scripts/stow.sh --simulate <pkg>       # dry-run a specific package
#
# Any argument starting with '-' is treated as a flag and forwarded to stow.
# Package names are any argument that does not start with '-'.
# When package names are given the ignore list is bypassed entirely.
#
# Common stow flags:
#   --adopt      Move existing files into the package, then symlink
#   --simulate   Dry-run: show what would be done without doing it
#   --restow     Re-stow (useful after moving files)
#   --delete     Remove symlinks for the given packages
#   --no-folding Expand directories rather than symlinking them
#
# Per-machine ignore file:
#   .stow-ignore.local  (git-ignored, lives at the repo root)
#   One package name per line. Blank lines and # comments are ignored.
#   Only consulted during a full stow (no package names given).
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

# ── Load ignore list ──────────────────────────────────────────────────────
_load_ignore_list() {
  local -n _ref=$1   # nameref: caller passes the name of their array
  [[ ! -f "$IGNORE_FILE" ]] && return
  while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    _ref+=("$line")
  done < "$IGNORE_FILE"
}

# ── Run stow with shared base flags + any extra flags + packages ──────────
_stow_packages() {
  local -a extra_flags=("${STOW_FLAGS[@]}")
  local -a packages=("$@")

  if [[ ${#packages[@]} -eq 0 ]]; then
    warn "No packages to stow."
    return
  fi

  info "Stowing: ${packages[*]}${extra_flags:+ (flags: ${extra_flags[*]})}"
  stow --dir "${DOTFILES_ROOT}/packages" \
       --target "$HOME" \
       --verbose 2 \
       "${extra_flags[@]+"${extra_flags[@]}"}" \
       "${packages[@]}"
}

# ── Main ──────────────────────────────────────────────────────────────────
stow_dotfiles() {
  local -a STOW_FLAGS=()
  local -a pkgs=()

  # Separate stow flags (start with '-') from package names
  for arg in "$@"; do
    if [[ "$arg" == -* ]]; then
      STOW_FLAGS+=("$arg")
    else
      pkgs+=("$arg")
    fi
  done

  if [[ ${#pkgs[@]} -gt 0 ]]; then
    # Explicit package list — bypass ignore file
    for pkg in "${pkgs[@]}"; do
      if [[ ! -d "${DOTFILES_ROOT}/packages/${pkg}" ]]; then
        error "Package not found: packages/${pkg}"
        exit 1
      fi
    done
    _stow_packages "${pkgs[@]}"
    success "Done."
    return
  fi

  # No packages given — stow all, minus the ignore list
  local -a ignore=()
  _load_ignore_list ignore

  if [[ ${#ignore[@]} -gt 0 ]]; then
    info "Ignoring packages (from .stow-ignore.local): ${ignore[*]}"
  fi

  local -a to_stow=()
  for pkg_dir in "${DOTFILES_ROOT}/packages"/*/; do
    pkg="$(basename "$pkg_dir")"
    local skip=0
    for ignored in "${ignore[@]}"; do
      [[ "$pkg" == "$ignored" ]] && skip=1 && break
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
