#                    __              ____         ___             
#  /'\_/`\          /\ \            /\  _`\   __ /\_ \            
# /\      \     __  \ \ \/'\      __\ \ \L\_\/\_\\//\ \      __   
# \ \ \__\ \  /'__`\ \ \ , <    /'__`\ \  _\/\/\ \ \ \ \   /'__`\ 
#  \ \ \_/\ \/\ \L\.\_\ \ \\`\ /\  __/\ \ \/  \ \ \ \_\ \_/\  __/ 
#   \ \_\\ \_\ \__/.\_\\ \_\ \_\ \____\\ \_\   \ \_\/\____\ \____\
#    \/_/ \/_/\/__/\/_/ \/_/\/_/\/____/ \/_/    \/_/\/____/\/____/

# ======================
# PLATFORM DETECTION
# ======================
OS := $(shell uname -s)
DISTRO := $(shell bash ./scripts/shared/detect-os.sh 2>/dev/null || echo unknown)

# Profile can be overridden via PROFILE=xxx on command line
PROFILE ?= $(DISTRO)
export PROFILE

# Select platform mise configuration even before shell dotfiles are deployed.
MISE_ENV ?= $(PROFILE)
export MISE_ENV

# ======================
# INHERITANCE HELPER
# ======================
# Run script with inheritance: check platform folder first, fall back to linux/
# Usage: $(call run_script,platform,layer)
define run_script
  @if [ -f ./scripts/$(1)/$(2).sh ]; then \
    bash ./scripts/$(1)/$(2).sh; \
  elif [ -f ./scripts/linux/$(2).sh ]; then \
    bash ./scripts/linux/$(2).sh; \
  else \
    echo "Error: Script $(2).sh not found for $(1)" >&2; exit 1; \
  fi
endef

# ======================
# ENTRY POINTS
# ======================
.PHONY: bootstrap sync pack link plug fresh-install

# Platform-aware bootstrap dispatcher
bootstrap:
ifeq ($(PROFILE),macos)
	@echo "Bootstrapping macOS..."
	@$(MAKE) bootstrap_macos
else ifeq ($(PROFILE),omarchy)
	@echo "Bootstrapping Omarchy..."
	@$(MAKE) bootstrap_omarchy
else ifeq ($(OS),Linux)
	@echo "Bootstrapping Linux ($(PROFILE))..."
	@$(MAKE) bootstrap_linux
else
	@echo "Error: Unsupported platform: $(OS)" >&2
	@exit 1
endif

# ======================
# PLATFORM-SPECIFIC BOOTSTRAP FLOWS
# ======================

# macOS bootstrap
.PHONY: bootstrap_macos
bootstrap_macos:
	$(call run_script,macos,prerequisites)
	$(call run_script,macos,packages)
	$(call run_script,macos,tools)
	$(call run_script,macos,plugins)
	$(call run_script,macos,config)
	$(call run_script,macos,hooks)

# Omarchy bootstrap (inherits from linux where applicable)
.PHONY: bootstrap_omarchy
bootstrap_omarchy:
	$(call run_script,omarchy,prerequisites)
	$(call run_script,omarchy,packages)  # Calls linux/packages.sh then omarchy/aur.sh
	$(call run_script,omarchy,tools)
	$(call run_script,omarchy,plugins)
	$(call run_script,omarchy,config)
	$(call run_script,omarchy,hooks)

# Linux bootstrap (generic, for future distros)
.PHONY: bootstrap_linux
bootstrap_linux:
	$(call run_script,linux,prerequisites)
	$(call run_script,linux,packages)    # mise bootstrap only, no AUR
	$(call run_script,linux,tools)
	$(call run_script,linux,plugins)
	$(call run_script,linux,config)
	$(call run_script,linux,hooks)

# ======================
# INCREMENTAL UPDATE TARGETS
# ======================
.PHONY: pack link plug sync

pack: packages
	@echo "✓ System packages installed"

link:
	@mise dotfiles apply

plug: plugins
	@echo "✓ Plugins installed"

sync: pack link plug
	@echo "✓ System synced"

# ======================
# COMPOSABLE LAYER TARGETS
# ======================
.PHONY: prerequisites packages tools plugins config hooks aur

prerequisites:
	$(call run_script,$(PROFILE),prerequisites)

packages:
	$(call run_script,$(PROFILE),packages)

aur:
	$(call run_script,omarchy,aur)

tools:
	$(call run_script,$(PROFILE),tools)

plugins:
	$(call run_script,$(PROFILE),plugins)

config:
	$(call run_script,$(PROFILE),config)

hooks:
	$(call run_script,$(PROFILE),hooks)

# ======================
# FRESH INSTALL
# ======================
.PHONY: fresh-install

fresh-install:
ifeq ($(PROFILE),macos)
	@bash ./scripts/macos/installer.sh
else ifeq ($(PROFILE),omarchy)
	@bash ./scripts/omarchy/installer.sh
else
	@bash ./scripts/linux/installer.sh
endif

# ======================
# UTILITIES
# ======================
.PHONY: apply_settings ghostty-shader zellij-plugins install_mise

# Backward compatibility: install_mise (now part of prerequisites)
install_mise:
	@bash ./scripts/install-mise.sh

# Apply OS-specific settings
apply_settings: config

# Zellij plugins (kept for backward compatibility)
zellij-plugins:
	@bash ./scripts/shared/install-zellij-plugin.sh

# Ghostty shader installer
ghostty-shader:
ifndef REPO
	$(error REPO is required. Usage: make ghostty-shader REPO=<git-url>)
endif
	@bash ./scripts/ghostty-shader.sh "$(REPO)"

# ======================
# LEGACY TARGETS (kept for compatibility)
# ======================
.PHONY: bootstrap_osx bootstrap_linux_legacy mise_bootstrap mise_install

bootstrap_osx: bootstrap_macos

bootstrap_linux_legacy: bootstrap_linux

mise_bootstrap: packages

mise_install: tools
