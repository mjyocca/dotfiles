# ================================================================
# Starship.io (see https://starship.rs/guide/)
# ================================================================
# Load starship prompt first before other tools
eval "$(starship init zsh)"

# Create/Load global env vars file
if [ -f ~/.global_env.sh ]; then
	# Load env vars
	. ~/.global_env.sh
else
	touch ~/.global_env.sh
	cat <<EOF > ~/.global_env.sh
#!/usr/bin/env bash
## export TEST_VAR="test"
EOF
fi

# =================================================================
# ASDF 📦 Package Manager (see https://asdf-vm.com/guide/getting-started.html)
# =================================================================
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
export PNPM_HOME="/Users/michaelyocca/Library/pnpm"
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
