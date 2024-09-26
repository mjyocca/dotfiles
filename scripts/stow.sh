#!/usr/bin/env bash

stow_dotfiles() {
  local to_stow="$(find stow -maxdepth 1 -type d -mindepth 1 | awk -F "/" '{print $NF}' ORS=' ')"
	echo "Stowing: $to_stow"
	stow --dir stow --verbose 2 --target "$HOME" $to_stow
}

stow_dotfiles
