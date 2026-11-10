# ================================================================
# mise — dev tool activation
# ================================================================
# Must precede every tool init below (starship, fzf, zoxide...):
# mise-managed binaries replace the former brew copies.
# Mirrors packages/bash/.bashrc on Omarchy.
# Non-interactive children inherit real tool paths. Keep shim setup out of
# .zshenv so child shells do not reselect runtimes using their own cwd.
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

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
# Shell completions (interactive only)
# =================================================================
autoload -Uz compinit && compinit

# =================================================================
# PNPM (see https://pnpm.io/installation)
# NOTE: `pnpm setup` overrides this current block `# pnpm ... # pnpm end`
# =================================================================
# pnpm
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# ================================================================
# CLI Tools
# ================================================================

# fzf (see https://github.com/junegunn/fzf)
source <(fzf --zsh)

# zoxide (see https://github.com/ajeetdsouza/zoxide)
eval "$(zoxide init zsh)"

source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Neovim aliases and variant shorthands (nv, nv-*, nvim-*)
[[ -f ~/.config/zsh/nvim.zsh ]] && source ~/.config/zsh/nvim.zsh

# ================================================================
# Local overrides (machine-specific, not committed)
# ================================================================
# ~/.zshrc.local is git-ignored. Use it for work-specific tools,
# credentials, aliases, or anything that should not be shared.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
