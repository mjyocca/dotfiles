# ~/.bashrc — cross-platform bash configuration
# Sourced by interactive non-login shells.
# ~/.bash_profile sources this for login shells.

# ================================================================
# Environment (all shells — keep this fast)
# ================================================================

# PATH: user-local bins
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

case ":$PATH:" in
  *":$HOME/bin:"*) ;;
  *) export PATH="$HOME/bin:$PATH" ;;
esac

# asdf shims (for all shells and scripts)
export ASDF_DATA_DIR="$HOME/.asdf"
case ":$PATH:" in
  *":${ASDF_DATA_DIR}/shims:"*) ;;
  *) export PATH="${ASDF_DATA_DIR}/shims:$PATH" ;;
esac

# XDG Base Directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# Standard environment
export EDITOR="nvim"
export PAGER="less"

# ================================================================
# Omarchy bootstrap (Linux only)
# ================================================================
if [[ -r /usr/share/omarchy/default/bash/env-bootstrap ]]; then
  source /usr/share/omarchy/default/bash/env-bootstrap
  # Non-interactive shells stop here (after env setup)
  [[ $- != *i* ]] && return
  # Source Omarchy defaults (starship, mise, zoxide, fzf, completions, aliases)
  source "${OMARCHY_PATH:-/usr/share/omarchy}/default/bash/rc"
else
  # Non-Omarchy: exit early for non-interactive
  [[ $- != *i* ]] && return
fi

# ================================================================
# Shell tools (cross-platform, interactive only)
# ================================================================
# On Omarchy, these are already handled by the rc sourced above.
# On other systems, initialize them ourselves.
if [[ -z "${OMARCHY_PATH:-}" ]]; then
  # Starship prompt
  command -v starship &>/dev/null && eval "$(starship init bash)"
  
  # mise activation
  command -v mise &>/dev/null && eval "$(mise activate bash)"
  
  # zoxide (better cd)
  command -v zoxide &>/dev/null && eval "$(zoxide init bash)"
  
  # fzf (fuzzy finder)
  if command -v fzf &>/dev/null; then
    # Try standard locations
    for fzf_setup in /usr/share/fzf/completion.bash /opt/homebrew/opt/fzf/shell/completion.bash; do
      [[ -f "$fzf_setup" ]] && source "$fzf_setup"
    done
    for fzf_keys in /usr/share/fzf/key-bindings.bash /opt/homebrew/opt/fzf/shell/key-bindings.bash; do
      [[ -f "$fzf_keys" ]] && source "$fzf_keys"
    done
  fi
  
  # bash-completion
  if [[ -z "$BASH_COMPLETION_VERSINFO" ]]; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
      source /usr/share/bash-completion/bash_completion
    elif [[ -f /opt/homebrew/share/bash-completion/bash_completion ]]; then
      source /opt/homebrew/share/bash-completion/bash_completion
    fi
  fi
fi

# ================================================================
# Tools not in Omarchy defaults (cross-platform)
# ================================================================

# direnv (see https://github.com/direnv/direnv)
command -v direnv &>/dev/null && eval "$(direnv hook bash)"

# PNPM (see https://pnpm.io/installation)
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# ================================================================
# Neovim aliases
# ================================================================
[[ -f ~/.config/bash/nvim.bash ]] && source ~/.config/bash/nvim.bash

# ================================================================
# Local overrides (machine-specific, not committed)
# ================================================================
# Create default if missing (same pattern as .zshrc.local)
if [[ ! -f ~/.bashrc.local ]]; then
  cat <<'EOF' > ~/.bashrc.local
# ~/.bashrc.local — machine-specific overrides, not committed to dotfiles
# Sourced at the end of ~/.bashrc on every interactive shell.
# Use this for work tools, credentials, aliases, or PATH additions
# that should not be shared across machines.
#
# Examples:
#   export GITHUB_TOKEN="..."
#   export PATH="/opt/corporate/bin:$PATH"
#   alias vpn="corporate-vpn connect"
EOF
fi
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local
