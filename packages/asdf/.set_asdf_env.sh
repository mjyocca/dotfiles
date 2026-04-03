# NOTE: Some subprocesses spawned within subschells don't always inherit configuration from current working directory.
# For example mason.nvim spawns subshell by Neovim where the working directory is not inherited and defaults to the root directory.
# In these cases, if there is no global language version, installation may fail for the LSP or packages.
#
# This script is meant to be executed from direnv .envrc file as `source ~/.set_asdf_env.sh`
# Exports all .tool-version entries to the current shells environemnt prior to starting Neovim. 
# This should allow spawned subshell within neovim to inherit these values as well.
if [ -f .tool-versions ]; then
  while read lang ver; do
    export ASDF_$(echo $lang | tr '[:lower:]' '[:upper:]')_VERSION=$ver
  done < .tool-versions
elif [ -f .go-version ]; then
  while read ver; do
    version=$(asdf current golang | cut -d' ' -f2)
    export ASDF_GOLANG_VERSION=$version
  done < .go-version
fi
