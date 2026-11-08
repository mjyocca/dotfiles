#!/usr/bin/env bash
# Omarchy inherits the Linux plugin interface; override install_plugins if needed.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../linux/plugins.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_plugins "$@"
fi
