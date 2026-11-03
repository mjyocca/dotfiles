#!/usr/bin/env bash
# OS/distribution detection utility
# Can be sourced or executed

get_os() {
    case "$(uname -s)" in
        Darwin)
            echo "macos"
            ;;
        Linux)
            # Check for specific distributions
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                case "${ID:-}" in
                    arch)
                        echo "arch"
                        ;;
                    manjaro|omarchy)
                        echo "omarchy"
                        ;;
                    ubuntu)
                        echo "ubuntu"
                        ;;
                    fedora)
                        echo "fedora"
                        ;;
                    *)
                        # Fallback to ID_LIKE
                        if [[ "${ID_LIKE:-}" == *"arch"* ]]; then
                            echo "omarchy"
                        elif [[ "${ID_LIKE:-}" == *"ubuntu"* || "${ID_LIKE:-}" == *"debian"* ]]; then
                            echo "ubuntu"
                        else
                            echo "unknown"
                        fi
                        ;;
                esac
            else
                echo "unknown"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# If script is executed (not sourced), output the OS
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    get_os
fi
