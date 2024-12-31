#!/usr/bin/env bash

. $PWD/scripts/utils.sh

setup_osx_launchctl() {
	info "Configuring MacOS launchagents"

	info "Enabling ssh agent on setup"
	cp "$HOME/dotfiles/osx/com.openssh.ssh-agent.plist" "$HOME/Library/LaunchAgents/"
	launchctl unload "$HOME/Library/LaunchAgents/com.openssh.ssh-agent.plist"
	launchctl load "$HOME/Library/LaunchAgents/com.openssh.ssh-agent.plist"
	launchctl enable gui/$(id -u)/com.openssh.ssh-agent

	info "Remapping Caps to Esc"
	cp "$HOME/dotfiles/osx/com.local.remap_caps_lock.plist" "$HOME/library/launchagents/"
	launchctl unload "$HOME/library/launchagents/com.local.remap_caps_lock.plist"
	launchctl load "$HOME/library/launchagents/com.local.remap_caps_lock.plist"
	launchctl enable gui/$(id -u)/com.local.remap_caps_lock
}

remap_keyboard_shortcut() {
  devices_json="$(hidutil list -m 'keyboard' -n)"
  keyboard_devices=$(echo "$devices_json" | jq -s 'group_by(.ProductID) | map({Product: .[0].Product, ProductID: .[0].ProductID, VendorID: .[0].VendorID }) | del(.[] | select(.ProductID==0 or .ProductID==null))')
  echo "$keyboard_devices"

  # echo "$keyboard_devices" | jq -c '.[]' | while read -r item; do
  #   # Extract values using jq
  #   product_name=$(echo "$item" | jq '.Product')
  #   product_id=$(echo "$item" | jq '.ProductID')
  #   vendor_id=$(echo "$item" | jq '.VendorID')

  #   # Print the id and value
  #   echo "Product: $product_name, ProductID: $product_id, VendorID: $vendor_id"
  #   defaults -currentHost write -g com.apple.keyboard.modifiermapping."$vendor_id"-"$product_id"-0 -array-add '{"HIDKeyboardModifierMappingDst"=30064771113; "HIDKeyboardModifierMappingSrc"=30064771129; }'
  # done
  # info "Writing mapping for built-in"
  # defaults -currentHost write -g com.apple.keyboard.modifiermapping.0-0-0 -array-add '{"HIDKeyboardModifierMappingDst"=0x700000029; "HIDKeyboardModifierMappingSrc"=0x700000039; }'
}

# Check if the script is being run directly or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# Script is being run directly, so call the function
  setup_osx_launchctl
fi
