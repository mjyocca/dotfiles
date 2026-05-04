# ================================================================
# Neovim aliases and variant shorthands
# ================================================================

# nv — shorthand for nvim.
# Future: will become a subcommand dispatcher (nv config-new, nv set-default, etc.)
# When that happens, remove this alias and replace with the binary at
# packages/scripts/.local/bin/nv.
alias nv='nvim'

# Auto-generate nv-<name> and nvim-<name> aliases for every stowed
# ~/.config/nvim-* variant at shell startup.
#
# e.g. for ~/.config/nvim-next:
#   nv-next   → NVIM_APPNAME=nvim-next nvim
#   nvim-next → NVIM_APPNAME=nvim-next nvim
#
# No-op if no nvim-* variants are stowed — safe on any machine.
for _nvim_dir in "$HOME"/.config/nvim-*(N); do
  _nvim_name="${_nvim_dir:t}"
  _nvim_short="${_nvim_name#nvim-}"
  alias "nv-${_nvim_short}=NVIM_APPNAME=${_nvim_name} nvim"
  alias "nvim-${_nvim_short}=NVIM_APPNAME=${_nvim_name} nvim"
done
unset _nvim_dir _nvim_name _nvim_short
