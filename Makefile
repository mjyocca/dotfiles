OS := $(shell uname -s)

# Determine current platform, package manager, and distro.
# Purpose: Detect the operating system and run appropriate target(s)
ifeq ($(OS), Darwin)
	PLATFORM := "OSX"
	PKG_MANAGER := brew
	INSTALL_CMD := $(PKG_MANAGER) install
	UPDATE_CMD := $(PKG_MANAGER) update
else ifeq ($(OS), Linux)
	PLATFORM := "Linux"
	DISTRO := $(shell awk -F= '/^ID=/{print $$2}' /etc/os-release)
	ifeq ($(DISTRO), ubuntu)
		PKG_MANAGER := apt-get
	else ifeq ($(DISTRO), debian)
		PKG_MANAGER := apt-get
	else ifeq ($(DISTRO), fedora)
		PKG_MANAGER := dnf
	else ifeq ($(DISTRO), centos)
		PKG_MANAGER := yum
	else ifeq ($(DISTRO), arch)
		PKG_MANAGER := pacman
	else
		$(error Unsupported Linux distribution: $(DISTRO))
	endif

	INSTALL_CMD := sudo $(PKG_MANAGER) install -y
	UPDATE_CMD := sudo $(PKG_MANAGER) update
endif

# ======================
## SHARED REUSABLE TARGETS
# ======================
# NOTE: Group of targets to continually execute after bootstrap/setup.

# Target: dotfiles
# Purpose: GNU Stow packages located within ./stow/** directory.
# Usage: Run `make dotfiles`.
dotfiles:
	@echo "Stowing Dotfile Packages..."
	@bash ./scripts/stow.sh

# Target: apply_settings
# Purpose: Apply operating system/GUI application settings that can configured through CLI/declarative means.
# Usage: Run `make apply_settings`.
apply_settings:
ifeq ($(PLATFORM), "OSX")
	$(MAKE) apply_defaults_osx 
else
	## TODO: Update to apply settings for Linux
	@echo "Unsupported OS: $(OS)"
	@echo "Platform $(PLATFORM)"
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
# Purpose: Leverages apply-user-defaults binary to apply MacOS/Application settings declared at ./osx/defaults.yml & ./osx/defaults.apps.yml
apply_defaults_osx:
	@echo "Applying OSX default settings ..."
	apply-user-defaults ./osx/defaults.yml
	@echo "Applying OSX Application default settings ..."
	apply-user-defaults ./osx/defaults.apps.yml

# Target: bootstrap_osx
# Purpose: Executes series of scripts/binaries to automate the installation and provisioning of software
bootstrap_osx: pre_install_osx install_osx_tools

pre_install_osx:
	@echo "Initializing macOS-specific tools..."
	@bash ./osx/core-utils.sh
	@bash ./osx/config.sh

install_osx_tools:
	@echo "Installing macOS-specific tools..."
	@brew bundle --file="~/Brewfile"
	@bash ./scripts/plugins.sh

# ======================
## LINUX SPECIFIC TARGETs
# ======================
# 
# TODO: Add automation to install necessary tools

bootstrap_linux: update_linux_packages install_linux_tools

update_linux_packages:
	@echo "Updating Linux-specific packages ..."
	@echo "updating pkg manager: $(PKG_MANAGER) for distro: $(DISTRO)"
	$(UPDATE_CMD)

install_linux_tools:
	@echo "Installing Linux-specific tools..."
	@echo "LINUX $(DISTRO)"
	$(INSTALL_CMD) git
	$(INSTALL_CMD) curl
	$(INSTALL_CMD) vim
