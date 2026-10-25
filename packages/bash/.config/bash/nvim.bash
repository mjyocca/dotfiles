# ================================================================
# Neovim aliases and variant shorthands
# ================================================================

# nv — shorthand for nvim
alias nv='nvim'

# Auto-generate nv-<name> and nvim-<name> aliases for every stowed
# ~/.config/nvim-* variant at shell startup.
#
# e.g. for ~/.config/nvim-next:
#   nv-next   → NVIM_APPNAME=nvim-next nvim
#   nvim-next → NVIM_APPNAME=nvim-next nvim
#
# No-op if no nvim-* variants are stowed — safe on any machine.

# Enable nullglob so the loop body doesn't run if no matches
shopt -s nullglob
for _nvim_dir in "$HOME"/.config/nvim-*; do
  if [[ -d "$_nvim_dir" ]]; then
    _nvim_name="$(basename "$_nvim_dir")"
    _nvim_short="${_nvim_name#nvim-}"
    alias "nv-${_nvim_short}=NVIM_APPNAME=${_nvim_name} nvim"
    alias "nvim-${_nvim_short}=NVIM_APPNAME=${_nvim_name} nvim"
  fi
done
unset _nvim_dir _nvim_name _nvim_short
shopt -u nullglob
