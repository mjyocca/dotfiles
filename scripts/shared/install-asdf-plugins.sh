#!/usr/bin/env bash
# Install only the tracked asdf plugins, not language versions or other plugins.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

for dependency in git mise; do
    command_exists "$dependency" || fatal "$dependency is required; run the packages/tools layers first."
done
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
asdf_binary="$(mise -C "$repo_root" which asdf --tool github:asdf-vm/asdf)"

info "Installing asdf plugins..."
installed_asdf_plugins="$("$asdf_binary" plugin list)"
while read -r plugin url; do
    if ! grep -Fxq "$plugin" <<< "$installed_asdf_plugins"; then
        "$asdf_binary" plugin add "$plugin" "$url"
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

success "asdf plugins installed (no language versions installed)"
