#!/usr/bin/env bash
# Prerequisites layer: Install base tools needed to run everything else
# Omarchy implementation (inherits from Linux base)
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

source "$(dirname "${BASH_SOURCE[0]}")/../shared/detect-os.sh"

if [[ "$(get_os)" != "omarchy" ]]; then
    fatal "This script is for Omarchy only"
fi

# Omarchy inherits prerequisites from Linux base
bash "$(dirname "${BASH_SOURCE[0]}")/../linux/prerequisites.sh"
