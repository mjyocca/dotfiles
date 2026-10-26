#!/usr/bin/env bash
# Stow dotfile packages into $HOME via GNU Stow.
#
# Usage:
#   ./scripts/stow.sh                        # stow packages for current OS profile
#   ./scripts/stow.sh <pkg> [<pkg> ...]      # stow specific packages (bypass profile + ignore)
#   ./scripts/stow.sh --adopt <pkg>          # pass extra flags to stow before pkg names
#   ./scripts/stow.sh --simulate <pkg>       # dry-run a specific package
#
# Any argument starting with '-' is treated as a flag and forwarded to stow.
# Package names are any argument that does not start with '-'.
# When package names are given the profile and ignore list are bypassed entirely.
#
# Profile-based selection:
#   On full stow (no explicit packages), the script loads the profile for the
#   detected OS. Profiles live in profiles/<os> and list which packages to stow.
#   Override the profile with: PROFILE=omarchy ./scripts/stow.sh
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
#   Subtracted from the profile list during a full stow.
#
# Example .stow-ignore.local:
#   # work machine — use corporate zsh config instead
#   zsh
#   homebrew

set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=utils.sh
source "${DOTFILES_ROOT}/scripts/utils.sh"

# Load OS detection
export DOTFILES_ROOT
# shellcheck source=detect-os.sh
source "${DOTFILES_ROOT}/scripts/detect-os.sh"

IGNORE_FILE="${DOTFILES_ROOT}/.stow-ignore.local"
PROFILE_FILE="${DOTFILES_ROOT}/profiles/${DOTFILES_PROFILE}"

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

# ── Load profile list ─────────────────────────────────────────────────────
_load_profile() {
  local -n _out=$1
  if [[ ! -f "$PROFILE_FILE" ]]; then
    error "No profile found: $PROFILE_FILE"
    error "Detected OS profile: $DOTFILES_PROFILE"
    error "Available profiles:"
    ls -1 "${DOTFILES_ROOT}/profiles/" 2>/dev/null | sed 's/^/  /' | sed 's/^/  /' >&2
    exit 1
  fi
  while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    # Validate package exists
    if [[ ! -d "${DOTFILES_ROOT}/packages/${line}" ]]; then
      warn "Profile references missing package: packages/${line}"
      continue
    fi
    _out+=("$line")
  done < "$PROFILE_FILE"
}

# ── Run stow with shared base flags + any extra flags + packages ──────────
_stow_packages() {
  local -a extra_flags=("${STOW_FLAGS[@]}")
  local -a packages=("$@")

  if [[ ${#packages[@]} -eq 0 ]]; then
    warn "No packages to stow."
    return
  fi

  info "Profile: $DOTFILES_PROFILE | Stowing: ${packages[*]}${extra_flags:+ (flags: ${extra_flags[*]})}"
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
    # Explicit package list — bypass profile and ignore file
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

  # No packages given — stow profile minus ignore list
  local -a profile_pkgs=()
  _load_profile profile_pkgs

  if [[ ${#profile_pkgs[@]} -eq 0 ]]; then
    warn "Profile '$DOTFILES_PROFILE' is empty or invalid."
    return
  fi

  local -a ignore=()
  _load_ignore_list ignore

  if [[ ${#ignore[@]} -gt 0 ]]; then
    info "Ignoring packages (from .stow-ignore.local): ${ignore[*]}"
  fi

  local -a to_stow=()
  for pkg in "${profile_pkgs[@]}"; do
    local skip=0
    for ignored in "${ignore[@]}"; do
      [[ "$pkg" == "$ignored" ]] && skip=1 && break
    done
    if [[ $skip -eq 0 ]]; then
      to_stow+=("$pkg")
    else
      warn "Skipping:  $pkg (ignored)"
    fi
  done

  _stow_packages "${to_stow[@]}"
  success "Done."
}

# Run directly or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  stow_dotfiles "$@"
fi
