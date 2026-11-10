# Shared Bash/Zsh runtime PATH setup. Source after loading shell-policy.sh.
# Shell built-ins only: this also runs during non-interactive startup.
if [ "${DOTFILES_RUNTIME_MANAGER:-asdf}" = asdf ]; then
  export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
  _dotfiles_runtime_shims="${ASDF_DATA_DIR}/shims"
else
  _dotfiles_runtime_shims="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims"
fi

# Move only the selected shims first, preserving other entries and empty fields.
_dotfiles_runtime_path="$_dotfiles_runtime_shims"
_dotfiles_runtime_remaining="${PATH}:"
while [ -n "$_dotfiles_runtime_remaining" ]; do
  _dotfiles_path_entry="${_dotfiles_runtime_remaining%%:*}"
  _dotfiles_runtime_remaining="${_dotfiles_runtime_remaining#*:}"
  if [ "$_dotfiles_path_entry" != "$_dotfiles_runtime_shims" ]; then
    _dotfiles_runtime_path="${_dotfiles_runtime_path}:$_dotfiles_path_entry"
  fi
done
export PATH="$_dotfiles_runtime_path"
unset _dotfiles_runtime_shims _dotfiles_runtime_path _dotfiles_runtime_remaining _dotfiles_path_entry
