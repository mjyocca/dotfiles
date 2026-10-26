#!/usr/bin/env bash
# Install git hooks from .githooks/ into .git/hooks/
# Run this after cloning the repo or when hooks are updated
#
# Usage:
#   scripts/install-git-hooks.sh          # Install all hooks
#   scripts/install-git-hooks.sh --check  # Check if hooks are installed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_SOURCE="$REPO_ROOT/.githooks"
HOOKS_TARGET="$REPO_ROOT/.git/hooks"

check_mode=false
if [[ "${1:-}" == "--check" ]]; then
  check_mode=true
fi

if [[ ! -d "$HOOKS_SOURCE" ]]; then
  echo "No .githooks directory found in $REPO_ROOT"
  exit 0
fi

if [[ ! -d "$HOOKS_TARGET" ]]; then
  echo "⚠️  Not a git repository: $REPO_ROOT"
  exit 1
fi

install_hook() {
  local hook_name="$1"
  local source="$HOOKS_SOURCE/$hook_name"
  local target="$HOOKS_TARGET/$hook_name"
  
  if [[ ! -f "$source" ]]; then
    return 0
  fi
  
  # Check if already installed
  if [[ -L "$target" ]]; then
    local current_target
    current_target="$(readlink "$target")"
    if [[ "$current_target" == "$source" ]]; then
      if [[ "$check_mode" == "true" ]]; then
        return 0
      fi
      echo "✓ $hook_name already installed"
      return 0
    fi
  fi
  
  if [[ "$check_mode" == "true" ]]; then
    echo "✗ $hook_name not installed"
    return 1
  fi
  
  # Install via symlink
  ln -sf "$source" "$target"
  chmod +x "$source"
  echo "✓ Installed $hook_name"
}

if [[ "$check_mode" == "true" ]]; then
  echo "Checking git hooks..."
  failed=0
  for hook in "$HOOKS_SOURCE"/*; do
    if [[ -f "$hook" ]]; then
      hook_name="$(basename "$hook")"
      if ! install_hook "$hook_name"; then
        failed=1
      fi
    fi
  done
  
  if [[ $failed -eq 1 ]]; then
    echo ""
    echo "Run 'scripts/install-git-hooks.sh' to install missing hooks"
    exit 1
  else
    echo "All hooks installed"
  fi
else
  echo "Installing git hooks from .githooks/ to .git/hooks/..."
  for hook in "$HOOKS_SOURCE"/*; do
    if [[ -f "$hook" ]]; then
      hook_name="$(basename "$hook")"
      install_hook "$hook_name"
    fi
  done
  echo ""
  echo "Done! Git hooks installed."
fi
