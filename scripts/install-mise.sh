#!/usr/bin/env bash

set -e

# Idempotent mise installation script
# Installs mise via package managers (not curl installer)
# - macOS: uses Homebrew
# - Linux: uses system package manager (pacman for Omarchy/Arch)

if command -v mise &> /dev/null; then
    echo "✓ mise is already installed: $(mise --version)"
    exit 0
fi

echo "Installing mise..."

# Detect OS and install via package manager
case "$(uname -s)" in
    Darwin)
        # macOS - use Homebrew
        if ! command -v brew &> /dev/null; then
            echo "Error: Homebrew not found. Please install Homebrew first."
            echo "Run: scripts/macos/installer.sh"
            exit 1
        fi
        brew install mise
        ;;
    Linux)
        # Linux - detect package manager
        if command -v pacman &> /dev/null; then
            # Omarchy/Arch - use pacman
            sudo pacman -S --needed --noconfirm mise
        else
            echo "Error: Unsupported Linux package manager"
            echo "mise must be installed via package manager (pacman for Omarchy/Arch)"
            exit 1
        fi
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
