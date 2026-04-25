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
# ASDF 📦 Package Manager (see https://asdf-vm.com/guide/getting-started.html)
# =================================================================
export PATH="$HOME/bin:$PATH"
export ASDF_DATA_DIR="$HOME/.asdf"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# append completions to fpath
fpath=(${ASDF_DATA_DIR:-$HOME/.asdf}/completions $fpath)
# initialise completions with ZSH's compinit
autoload -Uz compinit && compinit export PATH="$HOME/bin:$PATH"

# ASDF Golang plugin settings
# NOTE: Environment variables should generally be set before sourcing asdf.sh
export ASDF_GOLANG_MOD_VERSION_ENABLED=true
# Load Golang plugin
. ~/.asdf/plugins/golang/set-env.zsh

# =================================================================
# PNPM (see https://pnpm.io/installation)
# =================================================================
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac


# ================================================================
# 🧰 CLI Tools
# ================================================================

# direnv (see https://github.com/direnv/direnv)
eval "$(direnv hook zsh)"

# fzf (see https://github.com/junegunn/fzf)
source <(fzf --zsh)

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# ================================================================
# Local overrides (machine-specific, not committed)
# ================================================================
# ~/.zshrc.local is git-ignored. Use it for work-specific tools,
# credentials, aliases, or anything that should not be shared.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
