#!/usr/bin/env bash
# Install curated Omarchy packages. Safe to rerun: --needed skips up-to-date packages.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=package-lists.sh
source "$repo_root/scripts/omarchy/package-lists.sh"

usage() {
  echo 'Usage: install-packages.sh [--dry-run] [--machine NAME] [all|system|gui|aur]'
}

dry_run=false
selection=""
machine=""
while (($#)); do
  case "$1" in
    --dry-run) dry_run=true ;;
    --machine)
      [[ $# -ge 2 && -n "$2" && -z "$machine" ]] || { usage >&2; exit 2; }
      machine="$2"
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    all|system|gui|aur)
      [[ -z "$selection" ]] || { usage >&2; exit 2; }
      selection="$1"
      ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done

case "${selection:-all}" in
  all) lists=(system gui aur) ;;
  *) lists=("$selection") ;;
esac

# Parse every selected file before running any package manager. Capturing awk's
# status here (rather than through process substitution) preserves parse errors.
repo_packages=()
aur_packages=()
declare -A owners=()
files="$(package_list_files "$repo_root/packages/pacman" "$machine" "${lists[@]}")"
while IFS= read -r file; do
  parsed="$(read_package_list "$file")"
  while IFS= read -r package; do
    [[ -n "$package" ]] || continue
    owner=repo
    [[ "$file" != */packages-aur.txt ]] || owner=aur
    if [[ -n "${owners[$package]:-}" ]]; then
      if [[ "${owners[$package]}" != "$owner" ]]; then
        echo "Package listed as both repository and AUR: $package" >&2
        exit 1
      fi
      continue
    fi
    owners[$package]="$owner"
    if [[ "$owner" == repo ]]; then
      repo_packages+=("$package")
    else
      aur_packages+=("$package")
    fi
  done <<< "$parsed"
done <<< "$files"

# Preflight all required commands before starting the first transaction.
if [[ "$dry_run" == false ]]; then
  required=()
  ((${#repo_packages[@]} == 0)) || required+=(sudo pacman)
  ((${#aur_packages[@]} == 0)) || required+=(yay)
  for cmd in "${required[@]}"; do
    command -v "$cmd" >/dev/null || { echo "$cmd is required" >&2; exit 1; }
  done
  if ((${#aur_packages[@]})) && ((EUID == 0)); then
    echo 'Run as your normal user; yay cannot build AUR packages as root.' >&2
    exit 1
  fi
fi

run_install() {
  if [[ "$dry_run" == true ]]; then
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

if ((${#repo_packages[@]})); then
  run_install sudo pacman -S --needed -- "${repo_packages[@]}"
fi
if ((${#aur_packages[@]})); then
  run_install yay -S --needed --aur -- "${aur_packages[@]}"
fi
if ((${#repo_packages[@]} + ${#aur_packages[@]} == 0)); then
  echo 'No packages in selected lists.'
fi
