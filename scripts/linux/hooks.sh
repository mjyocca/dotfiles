#!/usr/bin/env bash
# Hooks layer: Install git hooks and automation
# Linux base implementation (works on macOS too)
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

info "Installing git hooks..."

if ! command_exists git; then
    fatal "git is not installed"
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    warn "Not in a git repository, skipping hooks installation"
    exit 0
fi

repo_root="$(git rev-parse --show-toplevel)"
if ! command_exists gitleaks && ! mise -C "$repo_root" which gitleaks --tool gitleaks >/dev/null 2>&1; then
    warn "gitleaks not found, skipping pre-commit hook installation"
    exit 0
fi

# Let Git resolve worktrees and core.hooksPath rather than assuming .git/hooks.
hooks_dir="$(git -C "$repo_root" rev-parse --path-format=absolute --git-path hooks)"
source_hook="$repo_root/.githooks/pre-commit"
target_hook="$hooks_dir/pre-commit"

[[ -f "$source_hook" && -x "$source_hook" ]] || fatal "Missing executable hook: $source_hook"

if [[ -L "$target_hook" && "$target_hook" -ef "$source_hook" ]]; then
    info "pre-commit hook already installed"
elif [[ -f "$target_hook" ]] && cmp -s "$source_hook" "$target_hook"; then
    info "pre-commit hook already installed"
elif [[ -e "$target_hook" || -L "$target_hook" ]]; then
    fatal "Existing pre-commit hook left untouched: $target_hook. Review it before replacing it."
else
    mkdir -p "$hooks_dir"
    ln -s "$source_hook" "$target_hook"
    success "gitleaks pre-commit hook installed"
fi

success "Git hooks installed"
