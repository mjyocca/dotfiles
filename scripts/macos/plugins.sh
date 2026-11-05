#!/usr/bin/env bash
# Plugins layer: Install editor/shell plugins
# macOS implementation
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

# macOS uses the same plugin logic as Linux
bash "$(dirname "${BASH_SOURCE[0]}")/../linux/plugins.sh"
