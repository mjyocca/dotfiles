# =================================================================
# PNPM (see https://pnpm.io/installation)
# Keep deterministic PATH changes before mise captures its activation state.
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
# Pre-mise local environment (machine-specific, not committed)
# ================================================================
# Keep machine-local PATH changes and variables needed by mise here so its
# activation snapshot includes them. Mise seeds this create-only file during
# dotfile deployment; use ~/.zshrc.local for aliases and hooks.
[[ -f ~/.zshrc.pre.local ]] && source ~/.zshrc.pre.local

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

# =================================================================
# Shell completions (interactive only)
# =================================================================
autoload -Uz compinit && compinit

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
# ~/.zshrc.local is git-ignored. Keep PATH and MISE_* changes in the pre-mise
# override so mise does not repeat its environment calculation at first prompt.
# Mise seeds both files create-only during dotfile deployment.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
