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

# Get git hooks directory
HOOKS_DIR="$(git rev-parse --show-toplevel)/.git/hooks"

# Install pre-commit hook for gitleaks
# Direct installation of gitleaks pre-commit hook
if command_exists gitleaks; then
    info "Installing gitleaks pre-commit hook..."
    cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/usr/bin/env bash
# Pre-commit hook: Run gitleaks to detect secrets
set -euo pipefail

if command -v gitleaks &> /dev/null; then
    echo "Running gitleaks..."
    gitleaks protect --staged --verbose
else
    echo "Warning: gitleaks not found, skipping secret detection"
fi
EOF
    chmod +x "$HOOKS_DIR/pre-commit"
    success "gitleaks pre-commit hook installed"
else
    warn "gitleaks not found, skipping pre-commit hook installation"
fi

success "Git hooks installed"
