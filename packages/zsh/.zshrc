# ================================================================
# Starship.io (see https://starship.rs/guide/)
# ================================================================
# Load starship prompt first before other tools
eval "$(starship init zsh)"

# Create/Load machine-local overrides file
if [[ ! -f ~/.zshrc.local ]]; then
	cat <<'EOF' > ~/.zshrc.local
# ~/.zshrc.local — machine-specific overrides, not committed to dotfiles
# Sourced at the end of ~/.zshrc on every interactive shell.
# Use this for work tools, credentials, aliases, or PATH additions
# that should not be shared across machines.
#
# Examples:
#   export GITHUB_TOKEN="..."
#   export PATH="/opt/corporate/bin:$PATH"
#   alias vpn="corporate-vpn connect"
EOF
fi

# =================================================================
# asdf — completions and language plugin hooks (interactive only)
# =================================================================
# PATH + ASDF_DATA_DIR are set in .zshenv; only interactive extras here.

# append completions to fpath
fpath=(${ASDF_DATA_DIR}/completions $fpath)
# initialise completions
autoload -Uz compinit && compinit

# Golang plugin settings
export ASDF_GOLANG_MOD_VERSION_ENABLED=true
. "${ASDF_DATA_DIR}/plugins/golang/set-env.zsh"

# =================================================================
# PNPM (see https://pnpm.io/installation)
# =================================================================
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# ================================================================
# CLI Tools
# ================================================================

# direnv (see https://github.com/direnv/direnv)
eval "$(direnv hook zsh)"

# fzf (see https://github.com/junegunn/fzf)
source <(fzf --zsh)

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# =================================================================
# asdf shims — re-prioritise for interactive shells
# =================================================================
# .zshenv sets shims early but tools like PNPM prepend to PATH later
# in .zshrc, pushing shims down and allowing macOS system binaries
# (e.g. system Ruby) to take precedence. Re-prepend at the end so
# asdf-managed versions always win in interactive sessions.
export PATH="$HOME/.asdf/shims:$PATH"

# Neovim aliases and variant shorthands (nv, nv-*, nvim-*)
[[ -f ~/.config/zsh/nvim.zsh ]] && source ~/.config/zsh/nvim.zsh

# ================================================================
# Local overrides (machine-specific, not committed)
# ================================================================
# ~/.zshrc.local is git-ignored. Use it for work-specific tools,
# credentials, aliases, or anything that should not be shared.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
