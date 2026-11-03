#!/usr/bin/env bash
# OS/distribution detection utility
# Can be sourced or executed

get_os() {
    if [[ -n "${PROFILE:-}" ]]; then
        printf '%s\n' "$PROFILE"
        return
    fi

    case "$(uname -s)" in
        Darwin)
            echo "macos"
            ;;
        Linux)
            # Omarchy normally retains ID=arch; do not classify all Arch as Omarchy.
            if [[ -d /usr/share/omarchy ]]; then
                echo "omarchy"
                return
            fi
            # Check for specific distributions
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                case "${ID:-}" in
                    arch|manjaro)
                        echo "$ID"
                        ;;
                    omarchy)
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
                            echo "arch"
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
