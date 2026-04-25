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
# Standard environment
# ================================================================
export EDITOR="nvim"
export PAGER="less"
