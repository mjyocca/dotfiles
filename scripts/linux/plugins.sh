#!/usr/bin/env bash
# Plugins layer: Install editor/shell plugins
# Linux base implementation
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

info "Installing plugins..."

for dependency in git mise curl; do
    command_exists "$dependency" || fatal "$dependency is required; run the packages/tools layers first."
done

# Installing a mise tool does not put it on the calling shell's PATH.
# Native lookup does not install tools or activate runtime defaults.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
gh_binary="$(mise -C "$repo_root" which gh --tool gh)"
run_gh() {
    "$gh_binary" "$@"
}

# Install TPM itself; installing/updating individual tmux plugins remains explicit.
if [[ ! -e "$HOME/.tmux/plugins/tpm" && ! -L "$HOME/.tmux/plugins/tpm" ]]; then
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

bash "$(dirname "${BASH_SOURCE[0]}")/../shared/install-asdf-plugins.sh"

installed_gh_extensions="$(run_gh extension list)"
if ! grep -Eq '(^|[[:space:]])dlvhdr/gh-dash([[:space:]]|$)' <<< "$installed_gh_extensions"; then
    run_gh extension install dlvhdr/gh-dash
fi

bash "$(dirname "${BASH_SOURCE[0]}")/../shared/install-zellij-plugin.sh"

success "Plugins installed"
