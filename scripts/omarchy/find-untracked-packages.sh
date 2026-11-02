#!/usr/bin/env bash
# Report explicit pacman packages absent from the curated lists.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=package-lists.sh
source "$repo_root/scripts/omarchy/package-lists.sh"
omarchy_base="${OMARCHY_BASE_PACKAGES:-/usr/share/omarchy/install/omarchy-base.packages}"

include_base=false
machine=""
usage() {
  echo 'Usage: find-untracked-packages.sh [--include-base] [--machine NAME]'
}
while (($#)); do
  case "$1" in
    --include-base) include_base=true ;;
    --machine)
      [[ $# -ge 2 && -n "$2" && -z "$machine" ]] || { usage >&2; exit 2; }
      machine="$2"
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done
command -v pacman >/dev/null || { echo 'pacman is required' >&2; exit 1; }

tracked=""
files="$(package_list_files "$repo_root/manifests/pacman" "$machine" system gui aur)"
while IFS= read -r file; do
  parsed="$(read_package_list "$file")"
  tracked+=$'\n'"$parsed"
done <<< "$files"
tracked="$(printf '%s\n' "$tracked" | LC_ALL=C sort -u)"

base=""
if [[ "$include_base" == false ]]; then
  if [[ -f "$omarchy_base" ]]; then
    base="$(read_package_list "$omarchy_base")"
  else
    echo "Warning: Omarchy base list not found: $omarchy_base" >&2
  fi
fi

report() {
  local label="$1" installed="$2" untracked
  untracked="$(LC_ALL=C comm -23 \
    <(printf '%s\n' "$installed" | LC_ALL=C sort -u) \
    <(printf '%s\n%s\n' "$tracked" "$base" | LC_ALL=C sort -u))"
  printf '\n%s:\n' "$label"
  if [[ -n "$untracked" ]]; then
    printf '%s\n' "$untracked"
  else
    echo '(none)'
  fi
}

# pacman returns 1 with no output when a filter matches no packages. Preserve
# real errors (including stderr), rather than treating them as an empty list.
query_packages() {
  local output status
  if output="$(pacman "$@" 2>&1)"; then
    printf '%s\n' "$output"
  else
    status=$?
    [[ "$status" == 1 && -z "$output" ]] && return 0
    printf '%s\n' "$output" >&2
    return "$status"
  fi
}
native="$(query_packages -Qqen)"
foreign="$(query_packages -Qqem)"
report 'Untracked repository packages' "$native"
report 'Untracked foreign packages (AUR or manually installed)' "$foreign"

printf '\nDirect dependencies should be tracked even if preinstalled.\n'
if [[ "$include_base" == false ]]; then
  echo 'Omarchy base names are excluded; use --include-base to include them.'
fi
echo 'mise tools are NOT filtered out: overlaps need review, not concealment.'
echo 'Compare with mise ls --current and mise config ls; package and tool names may differ.'
