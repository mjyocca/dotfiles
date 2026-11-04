#!/usr/bin/env bash
# Resolve an installed tracked tool without activation, downloads, or PATH fallback.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/environment.sh"

if (($# < 1 || $# > 2)) || [[ ! "$1" =~ ^[[:alnum:]_-]+$ ]]; then
    echo 'Usage: mise-tool-path.sh <executable> [tracked-tool-key]' >&2
    exit 2
fi
tool="$1"
request="${2:-$tool}"
if [[ ! "$request" =~ ^[[:alnum:]_][[:alnum:]_:+./-]*$ ]]; then
    echo "Invalid tracked tool key: $request" >&2
    exit 2
fi
command -v mise >/dev/null || { echo 'mise is required; run prerequisites first.' >&2; exit 1; }
config="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/packages/mise/.config/mise/config.toml"
version="$(mise --no-config config get --file "$config" "tools.\"$request\"")"
if [[ -z "$version" || "$version" == -* || "$version" == *[[:space:]]* ]]; then
    echo "Expected a simple tracked $request version." >&2
    exit 1
fi
# exec tool@latest can select an uninstalled release and fall back to PATH.
installed="$(mise --no-config latest --installed "$request@$version")"
[[ -n "$installed" ]] || { echo "No matching $request installed; run make tools first." >&2; exit 1; }
binary="$(mise --no-config which "$tool" --tool "$request@$installed")"
[[ -x "$binary" ]] || { echo "Installed $tool executable is missing; run make tools first." >&2; exit 1; }
printf '%s\n' "$binary"
