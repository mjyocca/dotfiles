#!/usr/bin/env bash
# Linux plugin interface.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/plugins.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_plugins "$@"
fi
