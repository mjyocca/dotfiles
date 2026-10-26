#!/usr/bin/env bash
# Install curated Omarchy packages. Safe to rerun: --needed skips up-to-date packages.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

install_list() {
  local file="$1"
  shift

  if [[ ! -f "$file" ]]; then
    echo "Package list not found: $file" >&2
    return 1
  fi

  local -a packages=()
  local package
  while IFS= read -r package; do
    [[ -z "$package" ]] && continue
    packages+=("$package")
  done < <(awk 'NF && $1 !~ /^#/ { print $1 }' "$file")

  if ((${#packages[@]})); then
    "$@" "${packages[@]}"
  fi
}

if (($# > 1)); then
  echo 'Usage: install-packages.sh [system|gui|aur]' >&2
  exit 2
fi

case "${1:-all}" in
  all) lists=(system gui aur) ;;
  system|gui|aur) lists=("$1") ;;
  *) echo 'Usage: install-packages.sh [system|gui|aur]' >&2; exit 2 ;;
esac

for list in "${lists[@]}"; do
  case "$list" in
    system)
      command -v pacman >/dev/null || { echo 'pacman is required' >&2; exit 1; }
      install_list "$repo_root/packages/pacman/packages.txt" sudo pacman -S --needed
      ;;
    gui|aur)
      command -v yay >/dev/null || { echo 'yay is required for GUI/AUR packages' >&2; exit 1; }
      install_list "$repo_root/packages/pacman/packages-$list.txt" yay -S --needed
      ;;
  esac
done
