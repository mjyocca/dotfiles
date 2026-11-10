# Shared Bash/Zsh mise shim setup.
# Shell built-ins only: this also runs during non-interactive startup.
_dotfiles_runtime_shims="${MISE_DATA_DIR:-$HOME/.local/share/mise}/shims"
_dotfiles_asdf_shims="${ASDF_DATA_DIR:-$HOME/.asdf}/shims"

# Remove inherited asdf shims and deduplicate mise shims. Preserve other entries
# and empty fields. Full interactive activation later adds real mise tool paths.
_dotfiles_runtime_path="$_dotfiles_runtime_shims"
_dotfiles_runtime_remaining="${PATH}:"
while [ -n "$_dotfiles_runtime_remaining" ]; do
  _dotfiles_path_entry="${_dotfiles_runtime_remaining%%:*}"
  _dotfiles_runtime_remaining="${_dotfiles_runtime_remaining#*:}"
  if [ "$_dotfiles_path_entry" != "$_dotfiles_runtime_shims" ] &&
     [ "$_dotfiles_path_entry" != "$_dotfiles_asdf_shims" ]; then
    _dotfiles_runtime_path="${_dotfiles_runtime_path}:$_dotfiles_path_entry"
  fi
done
export PATH="$_dotfiles_runtime_path"
unset _dotfiles_runtime_shims _dotfiles_asdf_shims _dotfiles_runtime_path _dotfiles_runtime_remaining _dotfiles_path_entry
