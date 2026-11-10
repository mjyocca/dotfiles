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

# Machine-wide policy; startup never reads project TOML to select hooks.
DOTFILES_ENVIRONMENT_LOADER=direnv
DOTFILES_RUNTIME_MANAGER=asdf
[[ -r "$HOME/.config/dotfiles/shell-policy.sh" ]] && source "$HOME/.config/dotfiles/shell-policy.sh"

[[ -r "$HOME/.config/dotfiles/runtime-path.sh" ]] && source "$HOME/.config/dotfiles/runtime-path.sh"

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
_dotfiles_omarchy_loaded=0
if [[ -r "${OMARCHY_PATH:-/usr/share/omarchy}/default/bash/env-bootstrap" ]]; then
  source "${OMARCHY_PATH:-/usr/share/omarchy}/default/bash/env-bootstrap"
  _dotfiles_omarchy_loaded=1
  # Keep Omarchy's Neovim untouched; prefer our isolated config when deployed.
  # Explicit NVIM_APPNAME selections (including variant aliases) take precedence.
  if [[ -d "$XDG_CONFIG_HOME/nvim-dotfiles" ]]; then
    export NVIM_APPNAME="${NVIM_APPNAME:-nvim-dotfiles}"
  fi
fi

# Non-interactive shells stop after environment setup.
if [[ $- != *i* ]]; then
  unset _dotfiles_omarchy_loaded
  return
fi

if [[ "$_dotfiles_omarchy_loaded" == 1 ]]; then
  # Source Omarchy defaults (starship, mise, zoxide, fzf, completions, aliases)
  # Upstream initializes mise itself. Adapt only that startup invocation in
  # direnv mode, before it can register a hook or load project environments.
  # Do not replace upstream rc or leave a command wrapper in the running shell.
  if [[ "$DOTFILES_ENVIRONMENT_LOADER" == direnv ]]; then
    _dotfiles_previous_mise="$(declare -f mise || true)"
    mise() {
      if [[ "${1:-}" == activate && "${2:-}" == bash ]]; then
        command mise "$@" --shims
      else
        command mise "$@"
      fi
    }
  fi
  source "${OMARCHY_PATH:-/usr/share/omarchy}/default/bash/rc"
  if [[ "$DOTFILES_ENVIRONMENT_LOADER" == direnv ]]; then
    unset -f mise
    [[ -z "$_dotfiles_previous_mise" ]] || eval "$_dotfiles_previous_mise"
    unset _dotfiles_previous_mise
  fi
fi

# ================================================================
# Shell tools (cross-platform, interactive only)
# ================================================================
# On Omarchy, these are already handled by the rc sourced above.
# On other systems, initialize them ourselves.
if [[ "$_dotfiles_omarchy_loaded" == 0 ]]; then
  # Starship prompt
  command -v starship &>/dev/null && eval "$(starship init bash)"
  
  # mise activation
  if command -v mise &>/dev/null; then
    if [[ "$DOTFILES_ENVIRONMENT_LOADER" == mise ]]; then
      eval "$(mise activate bash)"
    else
      eval "$(mise activate bash --shims)"
    fi
  fi
  
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

# Let the deployed bat config select its custom theme instead of Omarchy's ANSI default.
if [[ "$_dotfiles_omarchy_loaded" == 1 && "${BAT_THEME:-}" == ansi &&
      -r "$XDG_CONFIG_HOME/bat/config" &&
      -r "$XDG_CONFIG_HOME/bat/themes/GitHub Dark.tmTheme" ]]; then
  unset BAT_THEME
fi
unset _dotfiles_omarchy_loaded

# direnv (see https://github.com/direnv/direnv)
if [[ "$DOTFILES_ENVIRONMENT_LOADER" == direnv ]] && command -v direnv &>/dev/null; then
  eval "$(direnv hook bash)"
fi

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
# Preserve asdf ownership after other tools have prepended their paths.
if [[ "$DOTFILES_RUNTIME_MANAGER" == asdf ]]; then
  [[ -r "$HOME/.config/dotfiles/runtime-path.sh" ]] && source "$HOME/.config/dotfiles/runtime-path.sh"
fi

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
