# ~/.asdf-direnv.sh — source this from a project's .envrc via:
#   source ~/.asdf-direnv.sh
#
# Problem this solves:
#   asdf resolves language versions by walking up the directory tree looking
#   for .tool-versions (or legacy files like .go-version). This works fine in
#   the terminal, but subprocesses spawned by Neovim (e.g. Mason installing an
#   LSP) do not inherit $PWD from the project — they default to $HOME or /,
#   so asdf falls back to the global version or fails entirely.
#
# Solution:
#   Export explicit ASDF_<LANG>_VERSION env vars into the direnv environment.
#   Every subprocess Neovim spawns inherits these, bypassing directory-walk
#   resolution entirely.
#
# Reads (in order of preference):
#   .tool-versions  — asdf native format, all languages
#   .go-version     — Go legacy format (single version string)

if [ -f .tool-versions ]; then
  while IFS=' ' read -r lang ver; do
    # Skip blank lines and comments
    [ -z "$lang" ] && continue
    case "$lang" in \#*) continue ;; esac
    export "ASDF_$(echo "$lang" | tr '[:lower:]' '[:upper:]')_VERSION=$ver"
  done < .tool-versions
elif [ -f .go-version ]; then
  # .go-version contains a single bare version string, e.g. "1.22.3"
  ver="$(cat .go-version)"
  [ -n "$ver" ] && export "ASDF_GOLANG_VERSION=$ver"
fi
