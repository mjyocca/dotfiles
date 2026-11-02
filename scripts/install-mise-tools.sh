#!/usr/bin/env bash
# Install only repository-declared tools, not effective/asdf defaults.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="$repo_root/packages/mise/.config/mise/config.toml"

dry_run=false
case "${1:-}" in
  '') ;;
  --dry-run) dry_run=true ;;
  -h|--help) echo 'Usage: install-mise-tools.sh [--dry-run]'; exit 0 ;;
  *) echo 'Usage: install-mise-tools.sh [--dry-run]' >&2; exit 2 ;;
esac
(($# <= 1)) || { echo 'Too many arguments' >&2; exit 2; }
command -v mise >/dev/null || { echo 'mise is required' >&2; exit 1; }

# Let mise parse TOML and normalize the tools table. Capture its exit status
# before building requests; never fall back to a blanket install on failure.
tools="$(mise --no-config config get --file "$config" tools)"
requests=()
entry_pattern='^[[:space:]]*("([^"\\]+)"|([[:alnum:]_-]+))[[:space:]]*=[[:space:]]*"([^"\\]+)"[[:space:]]*$'
tool_pattern='^[[:alnum:]_][[:alnum:]_:+./-]*$'
while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*$ ]] && continue
  if [[ ! "$line" =~ $entry_pattern ]]; then
    echo "Bootstrap requires simple tool = \"version\" entries; unsupported entry: $line" >&2
    exit 1
  fi
  tool="${BASH_REMATCH[2]:-${BASH_REMATCH[3]}}"
  version="${BASH_REMATCH[4]}"
  if [[ ! "$tool" =~ $tool_pattern || "$version" == -* ]]; then
    echo "Invalid tool/version request: $line" >&2
    exit 1
  fi
  requests+=("$tool@$version")
done <<< "$tools"

if ((${#requests[@]} == 0)); then
  echo 'No tools in the shared mise config.'
elif [[ "$dry_run" == true ]]; then
  printf '%q ' mise --no-config install "${requests[@]}"
  printf '\n'
else
  mise --no-config install "${requests[@]}"
fi
