#!/usr/bin/env bash
# macOS Git hook interface.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/hooks.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_hooks "$@"
fi
