#!/usr/bin/env bash
# Plugins layer: Install editor/shell plugins
# Linux base implementation
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../shared/utils.sh"

info "Installing plugins..."

for dependency in git asdf mise curl; do
    command_exists "$dependency" || fatal "$dependency is required; run the packages/tools layers first."
done

# Installing a mise tool does not put it on the calling shell's PATH.
# Use only the tracked gh request; never activate effective/asdf runtime defaults.
gh_binary="$(bash "$(dirname "${BASH_SOURCE[0]}")/../shared/mise-tool-path.sh" gh)"
run_gh() {
    "$gh_binary" "$@"
}

# Install TPM itself; installing/updating individual tmux plugins remains explicit.
if [[ ! -e "$HOME/.tmux/plugins/tpm" && ! -L "$HOME/.tmux/plugins/tpm" ]]; then
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

installed_asdf_plugins="$(asdf plugin list)"
while read -r plugin url; do
    if ! grep -Fxq "$plugin" <<< "$installed_asdf_plugins"; then
        asdf plugin add "$plugin" "$url"
    fi
done <<'EOF'
nodejs https://github.com/asdf-vm/asdf-nodejs.git
deno https://github.com/asdf-community/asdf-deno.git
ruby https://github.com/asdf-vm/asdf-ruby.git
golang https://github.com/asdf-community/asdf-golang.git
java https://github.com/halcyon/asdf-java.git
rust https://github.com/asdf-community/asdf-rust.git
zig https://github.com/asdf-community/asdf-zig.git
bun https://github.com/cometkim/asdf-bun.git
EOF

installed_gh_extensions="$(run_gh extension list)"
if ! grep -Eq '(^|[[:space:]])dlvhdr/gh-dash([[:space:]]|$)' <<< "$installed_gh_extensions"; then
    run_gh extension install dlvhdr/gh-dash
fi

bash "$(dirname "${BASH_SOURCE[0]}")/../shared/install-zellij-plugin.sh"

success "Plugins installed"
