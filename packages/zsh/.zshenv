# ~/.zshenv — sourced by zsh for every shell (login, interactive, script, cron)
# Keep this file fast and minimal. Only export variables that non-interactive
# shells and scripts need. Do NOT put aliases, prompts, or slow init here.

# ================================================================
# PATH — user-local bins
# ================================================================
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

case ":$PATH:" in
  *":$HOME/bin:"*) ;;
  *) export PATH="$HOME/bin:$PATH" ;;
esac

# ================================================================
# asdf — shims must be on PATH for all shells and scripts
# ================================================================
export ASDF_DATA_DIR="$HOME/.asdf"

case ":$PATH:" in
  *":${ASDF_DATA_DIR}/shims:"*) ;;
  *) export PATH="${ASDF_DATA_DIR}/shims:$PATH" ;;
esac

# ================================================================
# XDG Base Directories
# ================================================================
# Force XDG paths on macOS so tools default to ~/.config, ~/.local/share, etc.
# rather than ~/Library/Application Support. Keeps config locations consistent
# with Linux and makes stow packages portable across both platforms.
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# ================================================================
# Standard environment
# ================================================================
export EDITOR="nvim"
export PAGER="less"
