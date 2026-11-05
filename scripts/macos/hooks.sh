#!/usr/bin/env bash
# Hooks layer: Install git hooks and automation
# macOS implementation (same as Linux base)
set -euo pipefail

bash "$(dirname "${BASH_SOURCE[0]}")/../linux/hooks.sh"
