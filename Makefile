OS := $(shell uname -s)

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

dotfiles:
	@echo "Stowing Dotfile Packages..."
	@bash ./scripts/stow.sh

pre_install_osx:
	@echo "Initializing macOS-specific tools..."
	@bash ./osx/core-utils.sh
	@bash ./osx/config.sh

# Common tasks
bootstrap: update_packages install_common_tools

update_packages:
	@echo "Updating packages on $(PLATFORM)..."
	@echo "$(UPDATE_CMD)"

install_common_tools:
	@echo "Installing common tools on $(PLATFORM)..."
	# $(INSTALL_CMD) git
	# $(INSTALL_CMD) curl

# OS-specific tasks
bootstrap_osx: bootstrap pre_install_osx install_osx_tools

install_osx_tools:
	@echo "Installing macOS-specific tools..."
	@brew bundle --file="~/Brewfile"
	@bash ./scripts/plugins.sh

# TODO: LINUX PLACEHOLDER
bootstrap_linux: bootstrap install_linux_tools

install_linux_tools:
	@echo "Installing Linux-specific tools..."
	@echo "LINUX $(DISTRO)"