#!/usr/bin/env bash
# Provisioning paths only: never source interactive shell startup or activate runtimes.
# Source from scripts, or invoke as: bash environment.sh <command> [args...].

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$PATH:$HOME/.local/bin" ;;
esac

if [[ "$(uname -s)" == Darwin ]]; then
    for provisioning_path in "/opt/homebrew/bin" "/opt/homebrew/sbin"; do
        case ":$PATH:" in
            *":$provisioning_path:"*) ;;
            *) export PATH="$PATH:$provisioning_path" ;;
        esac
    done
    unset provisioning_path
fi

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    if (($# == 0)); then
        echo 'Usage: environment.sh <command> [args...]' >&2
        exit 2
    fi
    exec "$@"
fi
