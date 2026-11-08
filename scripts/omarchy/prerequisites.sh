#!/usr/bin/env bash
# Omarchy inherits Linux prerequisites; override install_prerequisites if needed.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../linux/prerequisites.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    [[ "$(get_os)" == omarchy ]] || fatal 'This script is for Omarchy only'
    install_prerequisites "$@"
fi
