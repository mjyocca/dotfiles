#!/usr/bin/env bash

set -e

# Idempotent mise installation script
# Installs mise if not already present, safe to run multiple times

if command -v mise &> /dev/null; then
    echo "✓ mise is already installed: $(mise --version)"
    exit 0
fi

echo "Installing mise..."

# Detect OS and install accordingly
case "$(uname -s)" in
    Darwin)
        # macOS - should be installed via Homebrew, but fallback to installer if needed
        if command -v brew &> /dev/null; then
            brew install mise
        else
            echo "Error: Homebrew not found. Please install Homebrew first or add mise to Brewfile."
            exit 1
        fi
        ;;
    Linux)
        # Linux - use official installer
        curl https://mise.run | sh
        ;;
    *)
        echo "Error: Unsupported platform $(uname -s)"
        exit 1
        ;;
esac

# Verify installation
if command -v mise &> /dev/null; then
    echo "✓ mise installed successfully: $(mise --version)"
else
    echo "Error: mise installation failed"
    exit 1
fi
