#!/usr/bin/env bash
# Interactive AUR package installer with PKGBUILD review
# Reads from packages/aur/packages.txt and installs via yay with review prompts
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
aur_list="$repo_root/packages/aur/packages.txt"

# Check if yay is available
if ! command -v yay &>/dev/null; then
    echo "Error: yay is required for AUR package installation" >&2
    echo "Install yay first: https://github.com/Jguer/yay#installation" >&2
    exit 1
fi

# Check if AUR package list exists
if [[ ! -f "$aur_list" ]]; then
    echo "Warning: AUR package list not found at $aur_list"
    echo "Skipping AUR package installation"
    exit 0
fi

# Parse package list (skip comments and empty lines)
packages=()
while IFS= read -r line; do
    # Remove comments and trim whitespace
    line="${line%%#*}"
    line="${line// /}"
    [[ -n "$line" ]] && packages+=("$line")
done < "$aur_list"

if [[ ${#packages[@]} -eq 0 ]]; then
    echo "No AUR packages to install"
    exit 0
fi

echo "=== AUR Package Installation ==="
echo "Found ${#packages[@]} AUR package(s) to install"
echo ""

# Check which packages are already installed
installed=()
not_installed=()
for pkg in "${packages[@]}"; do
    if yay -Qi "$pkg" &>/dev/null; then
        installed+=("$pkg")
    else
        not_installed+=("$pkg")
    fi
done

if [[ ${#installed[@]} -gt 0 ]]; then
    echo "Already installed (${#installed[@]}):"
    printf '  - %s\n' "${installed[@]}"
    echo ""
fi

if [[ ${#not_installed[@]} -eq 0 ]]; then
    echo "All AUR packages are already installed"
    exit 0
fi

echo "Packages to install (${#not_installed[@]}):"
printf '  - %s\n' "${not_installed[@]}"
echo ""

# Prompt for installation
read -rp "Proceed with installation? [y/N] " response
case "$response" in
    [yY]|[yY][eE][sS])
        echo ""
        echo "Installing AUR packages interactively..."
        echo "You will be prompted to review PKGBUILD files for each package"
        echo ""
        
        for pkg in "${not_installed[@]}"; do
            echo "--- Installing: $pkg ---"
            # Enable review menus without inheriting saved automatic answers.
            if yay -S --needed --confirm --diffmenu --editmenu \
                --noanswerdiff --noansweredit -- "$pkg"; then
                echo "✓ Installed: $pkg"
            else
                echo "✗ Failed to install: $pkg" >&2
                read -rp "Continue with remaining packages? [Y/n] " continue_response
                case "$continue_response" in
                    [nN]|[nN][oO])
                        echo "Aborting AUR installation"
                        exit 1
                        ;;
                esac
            fi
            echo ""
        done
        
        echo "=== AUR Installation Complete ==="
        ;;
    *)
        echo "Skipping AUR package installation"
        exit 0
        ;;
esac
