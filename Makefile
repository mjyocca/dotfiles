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

setup_osx:
	@echo "Initializing macOS-specific tools..."
	@bash ./osx/core.sh
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
bootstrap_macos: bootstrap install_macos_tools

install_macos_tools:
	@echo "Installing macOS-specific tools..."
	$(INSTALL_CMD) htop
	$(INSTALL_CMD) wget  # For example, if wget isn't installed by default

# TODO: LINUX
# bootstrap_linux: bootstrap install_linux_tools

# install_linux_tools:
# 	@echo "Installing Linux-specific tools..."
# 	$(INSTALL_CMD) htop
# 	$(INSTALL_CMD) build-essential