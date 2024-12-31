# Starship
eval "$(starship init zsh)"

## Create/Load global env vars file
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

# ASDF
## asdf go plugin
## Environment variables should generally be set before sourcing asdf.sh
export ASDF_GOLANG_MOD_VERSION_ENABLED=true

. "$HOME/.asdf/asdf.sh"

## Golang plugin
. ~/.asdf/plugins/golang/set-env.zsh

# pnpm
export PNPM_HOME="/Users/michaelyocca/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# direnv hook
eval "$(direnv hook zsh)"

source <(fzf --zsh)

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
