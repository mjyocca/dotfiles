setup_github_ssh() {
	if [ -z "${SSH_PASSPHRASE}" ]; then
		echo "SSH_PASSPHRASE not set"
	else
		info "Using $SSH_PASSPHRASE"
		ssh-keygen -t ed25519 -C "$SSH_PASSPHRASE"
		ssh-keygen -t ed25519 -C ""

		info "Adding ssh key to keychain"
		ssh-add -K ~/.ssh/id_ed25519

		info "Remember add ssh key to github account 'pbcopy < ~/.ssh/id_ed25519.pub'"
	fi
}

# Check if the script is being run directly or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Script is being run directly, so call the function
  setup_github_ssh
fi