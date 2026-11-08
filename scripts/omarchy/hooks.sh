#!/usr/bin/env bash
# Omarchy inherits the Linux Git hook interface; override install_hooks if needed.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../linux/hooks.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_hooks "$@"
fi
