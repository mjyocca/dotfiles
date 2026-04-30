#!/usr/bin/env bash
# Import a Ghostty shader from a remote git repository.
#
# Usage:
#   ./scripts/ghostty-shader.sh <git-repo-url>
#
# Behaviour:
#   1. Clones the repo into ~/.cache/dotf/shaders/<owner>/<repo> (or pulls
#      latest if it already exists there).
#   2. Finds all *.glsl files recursively and presents an fzf multi-select
#      picker.
#   3. Copies selected shaders into the dotfiles package at:
#        packages/ghostty/.config/ghostty/shaders/
#      preserving subdirectory structure relative to the repo root.
#   4. Prepends an attribution header to each copied file (source URL +
#      commit hash at time of copy).
#   5. Optionally appends a `custom-shader = ...` line for each copied shader
#      to packages/ghostty/.config/ghostty/config.

set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=utils.sh
source "${DOTFILES_ROOT}/scripts/utils.sh"

# ── Helpers ───────────────────────────────────────────────────────────────

usage() {
  printf "Usage: %s <git-repo-url>\n" "$(basename "$0")" >&2
  exit 1
}

require_cmd() {
  if ! command -v "$1" &>/dev/null; then
    error "Required command not found: $1"
    exit 1
  fi
}

# Parse <owner>/<repo> from a git URL (https or ssh).
# e.g. https://github.com/sahaj-b/ghostty-cursor-shaders  -> sahaj-b/ghostty-cursor-shaders
#      git@github.com:sahaj-b/ghostty-cursor-shaders.git  -> sahaj-b/ghostty-cursor-shaders
parse_owner_repo() {
  local url="$1"
  # Strip trailing .git
  url="${url%.git}"
  # Strip everything up to the last two path components
  echo "${url}" | grep -oE '[^/:]+/[^/:]+$'
}

# ── Main ──────────────────────────────────────────────────────────────────

main() {
  [[ $# -lt 1 ]] && usage

  local repo_url="$1"

  require_cmd git
  require_cmd fzf

  local owner_repo owner repo
  owner_repo="$(parse_owner_repo "$repo_url")"
  owner="$(dirname "$owner_repo")"
  repo="$(basename "$owner_repo")"

  # ── 1. Clone or update ──────────────────────────────────────────────────
  local cache_dir="${HOME}/.cache/dotf/shaders/${owner_repo}"

  if [[ -d "${cache_dir}/.git" ]]; then
    info "Repo already cached at ${cache_dir} — pulling latest..."
    git -C "$cache_dir" pull --ff-only --quiet
  else
    info "Cloning ${repo_url} into cache..."
    mkdir -p "$(dirname "$cache_dir")"
    git clone --quiet "$repo_url" "$cache_dir"
  fi

  local commit_hash
  commit_hash="$(git -C "$cache_dir" rev-parse --short HEAD)"

  # ── 2. fzf picker ───────────────────────────────────────────────────────
  info "Finding .glsl files..."

  # Build list of glsl files relative to cache_dir
  local glsl_files
  glsl_files="$(find "$cache_dir" -type f -name '*.glsl' | sed "s|${cache_dir}/||" | sort)"

  if [[ -z "$glsl_files" ]]; then
    error "No .glsl files found in ${repo_url}"
    exit 1
  fi

  local selected
  selected="$(echo "$glsl_files" | fzf \
    --multi \
    --prompt="Select shaders (TAB to multi-select) > " \
    --header="Repo: ${owner}/${repo}  Commit: ${commit_hash}" \
    --preview="bat --color=always --style=numbers ${cache_dir}/{} 2>/dev/null || cat ${cache_dir}/{}" \
    --preview-window=right:60%)"

  if [[ -z "$selected" ]]; then
    warn "No shaders selected. Exiting."
    exit 0
  fi

  # ── 3 & 4. Copy with attribution header ─────────────────────────────────
  local dest_base="${DOTFILES_ROOT}/packages/ghostty/.config/ghostty/shaders"
  local config_file="${DOTFILES_ROOT}/packages/ghostty/.config/ghostty/config"

  local -a copied_shaders=()

  while IFS= read -r rel_path; do
    local src="${cache_dir}/${rel_path}"
    local dest="${dest_base}/${rel_path}"

    mkdir -p "$(dirname "$dest")"

    # Build attribution header
    local header
    header="$(cat <<EOF
// SOURCE: ${repo_url}
// FILE:   ${rel_path}
// COMMIT: ${commit_hash}
// COPIED: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
//
// This file was imported by make ghostty-shader.
// Original license applies. See upstream repo for details.
// ─────────────────────────────────────────────────────────────

EOF
)"

    # Prepend header only if not already present
    if head -1 "$src" | grep -q "^// SOURCE:"; then
      cp "$src" "$dest"
      warn "Attribution header already present in ${rel_path}, copying as-is."
    else
      { echo "$header"; cat "$src"; } > "$dest"
    fi

    success "Copied: ${rel_path} -> packages/ghostty/.config/ghostty/shaders/${rel_path}"
    copied_shaders+=("shaders/${rel_path}")
  done <<< "$selected"

  # ── 5. Optionally update ghostty config ─────────────────────────────────
  printf "\n"
  info "Copied ${#copied_shaders[@]} shader(s). Append custom-shader entries to ghostty config?"
  printf "  Config: %s\n\n" "$config_file"

  for shader_path in "${copied_shaders[@]}"; do
    printf "  custom-shader = %s\n" "$shader_path"
  done

  printf "\nAppend these lines? [y/N] "
  read -r answer

  if [[ "${answer,,}" == "y" ]]; then
    {
      printf "\n# Added by make ghostty-shader (%s)\n" "$(date -u +"%Y-%m-%d")"
      for shader_path in "${copied_shaders[@]}"; do
        printf "custom-shader = %s\n" "$shader_path"
      done
    } >> "$config_file"
    success "ghostty config updated."
  else
    info "Skipped config update. Add manually if needed:"
    for shader_path in "${copied_shaders[@]}"; do
      printf "  custom-shader = %s\n" "$shader_path"
    done
  fi

  printf "\n"
  success "Done. Run 'make stow PKG=ghostty' if symlinks need refreshing."
}

main "$@"
