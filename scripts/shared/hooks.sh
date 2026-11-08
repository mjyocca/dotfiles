#!/usr/bin/env bash
# Shared repository Git hook implementation.

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

install_hooks() {
    local hooks_dir source_hook target_hook
    info 'Installing git hooks...'
    command_exists git || fatal 'git is not installed'
    if ! git -C "$DOTFILES_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
        warn 'Not in a git repository, skipping hooks installation'
        return 0
    fi

    if ! command_exists gitleaks && ! mise -C "$DOTFILES_ROOT" which gitleaks --tool gitleaks >/dev/null 2>&1; then
        warn 'gitleaks not found, skipping pre-commit hook installation'
        return 0
    fi

    # Let Git resolve worktrees and core.hooksPath rather than assuming .git/hooks.
    hooks_dir="$(git -C "$DOTFILES_ROOT" rev-parse --path-format=absolute --git-path hooks)"
    source_hook="$DOTFILES_ROOT/.githooks/pre-commit"
    target_hook="$hooks_dir/pre-commit"
    [[ -f "$source_hook" && -x "$source_hook" ]] || fatal "Missing executable hook: $source_hook"

    if [[ -L "$target_hook" && "$target_hook" -ef "$source_hook" ]]; then
        info 'pre-commit hook already installed'
    elif [[ -f "$target_hook" ]] && cmp -s "$source_hook" "$target_hook"; then
        info 'pre-commit hook already installed'
    elif [[ -e "$target_hook" || -L "$target_hook" ]]; then
        fatal "Existing pre-commit hook left untouched: $target_hook. Review it before replacing it."
    else
        mkdir -p "$hooks_dir"
        ln -s "$source_hook" "$target_hook"
        success 'gitleaks pre-commit hook installed'
    fi
    success 'Git hooks installed'
}
