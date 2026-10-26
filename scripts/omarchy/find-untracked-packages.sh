#!/usr/bin/env bash
# Helper script to identify installed packages not tracked in dotfiles
# Shows packages that might need to be added to packages.txt or packages-gui.txt

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PACKAGES_TXT="$REPO_ROOT/packages/pacman/packages.txt"
PACKAGES_GUI_TXT="$REPO_ROOT/packages/pacman/packages-gui.txt"
OMARCHY_BASE="/usr/share/omarchy/install/omarchy-base.packages"
MISE_CONFIG="$REPO_ROOT/packages/mise/.config/mise/config.toml"

# Check if running on Arch-based system
if ! command -v pacman &> /dev/null; then
    echo "Error: This script requires pacman (Arch-based system)"
    exit 1
fi

# Check if required files exist
if [[ ! -f "$PACKAGES_TXT" ]]; then
    echo "Error: packages.txt not found at $PACKAGES_TXT"
    exit 1
fi

if [[ ! -f "$OMARCHY_BASE" ]]; then
    echo "Warning: omarchy-base.packages not found at $OMARCHY_BASE"
    echo "Skipping Omarchy default packages filter"
    OMARCHY_BASE=""
fi

if [[ ! -f "$MISE_CONFIG" ]]; then
    echo "Warning: mise config not found at $MISE_CONFIG"
    echo "Skipping mise-managed packages filter"
    MISE_CONFIG=""
fi

echo "Analyzing installed packages..."
echo ""

# Get all explicitly installed packages
installed=$(pacman -Qqen | sort)

# Get tracked packages (from both files)
tracked=""
if [[ -f "$PACKAGES_TXT" ]]; then
    tracked=$(grep -v '^#' "$PACKAGES_TXT" | grep -v '^$' | sort -u)
fi
if [[ -f "$PACKAGES_GUI_TXT" ]]; then
    gui_tracked=$(grep -v '^#' "$PACKAGES_GUI_TXT" | grep -v '^$' | sort -u)
    tracked=$(echo -e "$tracked\n$gui_tracked" | sort -u)
fi

# Get Omarchy base packages (if available)
omarchy_base=""
if [[ -n "$OMARCHY_BASE" && -f "$OMARCHY_BASE" ]]; then
    omarchy_base=$(grep -v '^#' "$OMARCHY_BASE" | grep -v '^$' | sort -u)
fi

# Get mise-managed packages (if available)
mise_packages=""
if [[ -n "$MISE_CONFIG" && -f "$MISE_CONFIG" ]]; then
    # Extract tool names from mise config (lines like "tool = "version"")
    mise_packages=$(grep -E '^\w+\s*=' "$MISE_CONFIG" | cut -d'=' -f1 | tr -d ' ' | sort -u)
fi

# Find untracked packages
untracked=$(comm -23 <(echo "$installed" | sort) <(echo "$tracked" | sort))

# Filter out Omarchy base packages if available
if [[ -n "$omarchy_base" ]]; then
    untracked=$(comm -23 <(echo "$untracked" | sort) <(echo "$omarchy_base" | sort))
fi

# Filter out mise-managed packages if available
if [[ -n "$mise_packages" ]]; then
    untracked=$(comm -23 <(echo "$untracked" | sort) <(echo "$mise_packages" | sort))
fi

# Display results
if [[ -z "$untracked" ]]; then
    echo "✓ All installed packages are tracked!"
    exit 0
fi

echo "Found $(echo "$untracked" | wc -l) untracked packages:"
echo ""
echo "$untracked"
echo ""
echo "Consider adding these to:"
echo "  - packages/pacman/packages.txt (system/CLI packages)"
echo "  - packages/pacman/packages-gui.txt (GUI applications)"
echo ""
echo "Or add them to mise if they're dev tools:"
echo "  - packages/mise/.config/mise/config.toml"
