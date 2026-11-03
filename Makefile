#                    __              ____         ___             
#  /'\_/`\          /\ \            /\  _`\   __ /\_ \            
# /\      \     __  \ \ \/'\      __\ \ \L\_\/\_\\//\ \      __   
# \ \ \__\ \  /'__`\ \ \ , <    /'__`\ \  _\/\/\ \ \ \ \   /'__`\ 
#  \ \ \_/\ \/\ \L\.\_\ \ \\`\ /\  __/\ \ \/  \ \ \ \_\ \_/\  __/ 
#   \ \_\\ \_\ \__/.\_\\ \_\ \_\ \____\\ \_\   \ \_\/\____\ \____\
#    \/_/ \/_/\/__/\/_/ \/_/\/_/\/____/ \/_/    \/_/\/____/\/____/
                                                               
                                                                

# Determine current platform, package manager, and distro.
# Purpose: Detect the operating system and run appropriate target(s)
#
OS := $(shell uname -s)

# Profile detection - can be overridden via PROFILE=xxx on command line
PROFILE ?= $(shell bash ./scripts/detect-os.sh --print 2>/dev/null || echo unknown)
export PROFILE

ifeq ($(OS), Darwin)
	PLATFORM := "OSX"
	PKG_MANAGER := brew
	INSTALL_CMD := $(PKG_MANAGER) install
	UPDATE_CMD := $(PKG_MANAGER) update
else ifeq ($(OS), Linux)
	PLATFORM := "Linux"
	# Extract ID from /etc/os-release, fallback to ID_LIKE for derivatives
	_DISTRO_ID := $(shell awk -F= '/^ID=/{print $$2}' /etc/os-release 2>/dev/null | tr -d '"')
	_DISTRO_LIKE := $(shell awk -F= '/^ID_LIKE=/{print $$2}' /etc/os-release 2>/dev/null | tr -d '"')
	
	# Map distro to package manager
	# Omarchy: ID=omarchy, ID_LIKE=arch → pacman
	# Arch: ID=arch → pacman
	# Ubuntu/Debian → apt-get
	# Fedora → dnf
	# CentOS → yum
	ifeq ($(_DISTRO_ID),ubuntu)
		PKG_MANAGER := apt-get
	else ifeq ($(_DISTRO_ID),debian)
		PKG_MANAGER := apt-get
	else ifeq ($(_DISTRO_ID),fedora)
		PKG_MANAGER := dnf
	else ifeq ($(_DISTRO_ID),centos)
		PKG_MANAGER := yum
	else ifeq ($(_DISTRO_ID),arch)
		PKG_MANAGER := pacman
	else ifeq ($(_DISTRO_ID),omarchy)
		# Omarchy is arch-based
		PKG_MANAGER := pacman
	else ifneq ($(filter arch,$(_DISTRO_LIKE)),)
		# Fallback: if ID_LIKE contains "arch", use pacman
		PKG_MANAGER := pacman
	else
		$(error Unsupported Linux distribution: $(_DISTRO_ID) (ID_LIKE: $(_DISTRO_LIKE)))
	endif

	DISTRO := $(_DISTRO_ID)
	INSTALL_CMD := sudo $(PKG_MANAGER) install -y
	UPDATE_CMD := sudo $(PKG_MANAGER) update
	ifeq ($(PKG_MANAGER),pacman)
		INSTALL_CMD := sudo pacman -S --needed
		UPDATE_CMD := sudo pacman -Syu
	endif
endif

# ======================
## SHARED REUSABLE TARGETS
# ======================
# NOTE: Group of targets to continually execute after bootstrap/setup.

# Target: ghostty-shader
# Purpose: Import a Ghostty GLSL shader from a remote git repository.
#          Clones (or pulls) the repo into a local cache, presents an fzf
#          multi-select picker of all .glsl files, copies selected shaders
#          into packages/ghostty with an attribution header, and optionally
#          appends custom-shader entries to the ghostty config.
# Usage: make ghostty-shader REPO=<git-url>
#   e.g. make ghostty-shader REPO=https://github.com/sahaj-b/ghostty-cursor-shaders
ghostty-shader:
ifndef REPO
	$(error REPO is required. Usage: make ghostty-shader REPO=<git-url>)
endif
	@bash ./scripts/ghostty-shader.sh "$(REPO)"

# Target: zellij-plugins
# Purpose: Download zellij wasm plugins from their release pages.
#          Runs during bootstrap; can also be called manually.
#          Idempotent - skips download if plugin already exists.
.PHONY: zellij-plugins
zellij-plugins:
	@mkdir -p $(HOME)/.config/zellij/plugins
	@if [ ! -f $(HOME)/.config/zellij/plugins/zellij-autolock.wasm ]; then \
		echo "Downloading zellij-autolock..."; \
		curl -fSL -o $(HOME)/.config/zellij/plugins/zellij-autolock.wasm \
			https://github.com/fresh2dev/zellij-autolock/releases/download/0.2.2/zellij-autolock.wasm; \
		echo "✓ zellij-autolock v0.2.2 installed"; \
	else \
		echo "✓ zellij-autolock v0.2.2 already installed"; \
	fi

# Target: pack
# Purpose: Install system packages for current platform via mise bootstrap
# Usage: make pack
#        make pack PROFILE=omarchy  # force platform
.PHONY: pack
pack:
	@echo "Installing system packages via mise bootstrap..."
	@mise bootstrap

# Target: link
# Purpose: Deploy dotfile symlinks via mise
# Usage: make link
.PHONY: link
link:
	@echo "Linking dotfiles via mise..."
	@mise dotfiles apply

# Target: plug
# Purpose: Install plugins managed outside mise
# Usage: make plug
.PHONY: plug
plug:
	@echo "Installing plugins..."
	@$(MAKE) zellij-plugins

# Target: sync
# Purpose: Install packages + link dotfiles + install plugins
# Usage: make sync
.PHONY: sync
sync: pack link plug
	@echo "✓ System synced"

# Target: apply_settings
# Purpose: Apply operating system/GUI application settings that can configured through CLI/declarative means.
# Usage: Run `make apply_settings`.
apply_settings:
ifeq ($(PLATFORM), "OSX")
	$(MAKE) apply_defaults_osx 
else
	## TODO: Implement OS-specific settings application for Linux profiles
	## For Omarchy: most user settings are in ~/.config/ and managed via mise.
	## Consider adding: gsettings, dconf, or profile-specific setting scripts.
	@echo "Linux settings application not yet implemented for profile: $(PROFILE)"
	@echo "Most settings are managed via mise in ~/.config/"
	@echo "See: .config/mise/config.omarchy.toml and AGENTS.md for Omarchy conventions."
endif

# ======================
## BOOTSTRAP / SETUP TARGET ENTRYPOINT
# ======================
#
# NOTE: Meant to run when provisioning a new machine. But should gracefully check if software is installed in each step either manually or through package managers.
bootstrap:
ifeq ($(PLATFORM), "OSX")
	@echo "Bootstrapping..."
	@echo "Detected $(PLATFORM)."
	$(MAKE) bootstrap_osx
else ifeq ($(PLATFORM), "Linux")
	@echo "Bootstrapping..."
	@echo "Detected $(PLATFORM)."
	$(MAKE) bootstrap_linux
endif

# ===========================
# ===========================
## OS SPECIFC TARGETS BELOW
# ===========================
# ===========================

# ======================
## MacOS/OSX Specific Targets
# ======================

# Target: apply_defaults_osx
# Purpose: Leverages apply-user-defaults binary to apply MacOS/Application settings declared at ./scripts/macos/defaults.yml & ./scripts/macos/defaults.apps.yml
apply_defaults_osx:
	@echo "Applying OSX default settings ..."
	apply-user-defaults ./scripts/macos/defaults.yml
	@echo "Applying OSX Application default settings ..."
	apply-user-defaults ./scripts/macos/defaults.apps.yml

# Target: install_mise
# Purpose: Install mise via package manager (not curl installer)
# - macOS: brew install mise
# - Omarchy: sudo pacman -S mise
# Idempotent - skips if already installed
install_mise:
	@bash ./scripts/install-mise.sh

# Target: bootstrap_osx
# Purpose: Executes series of scripts/binaries to automate the installation and provisioning of software
# New flow: prerequisites → mise → bootstrap packages → dev tools → plugins
bootstrap_osx: pre_install_osx install_mise mise_bootstrap mise_install zellij-plugins

pre_install_osx:
	@echo "Initializing macOS-specific tools..."
	@bash ./scripts/macos/core-utils.sh
	@bash ./scripts/macos/config.sh

# Target: mise_bootstrap
# Purpose: Install system packages via mise's [bootstrap.packages]
# Reads .config/mise/config.toml + config.macos.toml (or config.omarchy.toml)
mise_bootstrap:
	@echo "Installing system packages via mise bootstrap..."
	@mise bootstrap

# Target: aur_install
# Purpose: Install AUR packages interactively with PKGBUILD review (Omarchy only)
# Runs after mise bootstrap to handle user-submitted packages
aur_install:
ifeq ($(PROFILE),omarchy)
	@echo "Installing AUR packages interactively..."
	@bash ./scripts/linux/aur-installer.sh
else
	@echo "AUR packages not applicable on this platform"
endif

brew_bundle:
	@brew bundle --file="$(CURDIR)/packages/homebrew/Brewfile"
# ======================
## LINUX SPECIFIC TARGETs
# ======================
# 
# Omarchy installs curated lists; other Linux profiles retain their existing setup.

# Recursive makes enforce provisioning order even with make -j.
.PHONY: bootstrap_linux update_linux_packages install_linux_tools install_mise mise_install install_git_hooks
bootstrap_linux:
	$(MAKE) update_linux_packages
	$(MAKE) install_mise
	$(MAKE) mise_bootstrap
	$(MAKE) aur_install
	$(MAKE) mise_install
	$(MAKE) install_git_hooks
	$(MAKE) zellij-plugins
	@echo "Packages installed. Run make dotfiles to activate the repository configuration."

update_linux_packages:
	@echo "Updating Linux-specific packages ..."
	@echo "updating pkg manager: $(PKG_MANAGER) for distro: $(DISTRO)"
	$(UPDATE_CMD)

install_linux_tools:
	@echo "Installing Linux-specific tools..."
	@echo "Profile: $(PROFILE) | DISTRO: $(DISTRO)"
ifneq ($(PROFILE),omarchy)
	$(INSTALL_CMD) git
	$(INSTALL_CMD) curl
	$(INSTALL_CMD) vim
	$(INSTALL_CMD) stow
	$(INSTALL_CMD) gitleaks
else
	@echo "Omarchy packages are managed by mise bootstrap (see mise_bootstrap target)"
endif

install_git_hooks:
	@echo "Installing git hooks..."
	@bash ./scripts/install-git-hooks.sh

# ===========================
# MISE TARGETS (Dev Tools)
# ===========================

mise_install:
	@echo "Installing mise-managed dev tools..."
	@bash ./scripts/install-mise-tools.sh

mise_update:
	@echo "Updating mise-managed dev tools..."
	@mise update
