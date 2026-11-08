# Make owns lifecycle ordering; platform scripts compose shared implementations.
.DEFAULT_GOAL := help

DETECTED_PROFILE := $(shell bash ./scripts/shared/detect-os.sh)
PROFILE ?= $(DETECTED_PROFILE)
MISE_ENV ?= $(PROFILE)
export PROFILE MISE_ENV

.PHONY: help check-profile bootstrap sync prerequisites packages repos link tools \
        plugins config hooks aur ghostty-shader

help:
	@printf '%s\n' \
	  'Usage: make <target> [PROFILE=<platform>]' \
	  '' \
	  'Lifecycle (changes this machine):' \
	  '  bootstrap      prerequisites → packages → repos → link → tools → plugins → config → hooks' \
	  '  sync           packages → repos → link → tools → plugins' \
	  '' \
	  'Individual stages:' \
	  '  prerequisites  Install/reuse mise and platform prerequisites' \
	  '  packages       Install system packages (includes interactive AUR on Omarchy)' \
	  '  repos          Provision optional configured workspace checkouts' \
	  '  link           Deploy dotfiles; scope with DOTFILES_ARGS="--dry-run <target>"' \
	  '  tools          Install effective mise tool requests; accepts TOOLS_ARGS' \
	  '  plugins        Install tracked plugin integrations, not language runtimes' \
	  '  config         Apply platform preferences, where implemented' \
	  '  hooks          Install the repository Gitleaks pre-commit hook' \
	  '' \
	  'Utilities:' \
	  '  aur            Install Omarchy AUR packages with interactive review' \
	  '  ghostty-shader Import shaders; requires REPO=<git-url>' \
	  '' \
	  'Supported profiles: macos (Apple Silicon), omarchy. Other distros need configuration and scripts.' \
	  "Selected profile: $$PROFILE (MISE_ENV=$$MISE_ENV)"

# Detection is not support: require a matching provisioning configuration.
check-profile:
	@case "$$PROFILE" in ''|*[!a-z0-9_-]*) \
	  echo "Invalid PROFILE=$$PROFILE" >&2; exit 1;; esac
	@test -f ".config/mise/config.$$PROFILE.toml" || \
	  { echo "No provisioning configuration for PROFILE=$$PROFILE." >&2; exit 1; }
	@test "$$MISE_ENV" = "$$PROFILE" || \
	  { echo "MISE_ENV=$$MISE_ENV conflicts with PROFILE=$$PROFILE; select the same single platform." >&2; exit 1; }

bootstrap sync prerequisites packages repos link tools plugins config hooks aur: | check-profile

# Platform entrypoints are explicit; inheritance lives in their source statements.
define run_platform_script
	@script="./scripts/$$PROFILE/$(1).sh"; \
	 if [ ! -f "$$script" ]; then \
	   echo "Missing platform stage: $$script" >&2; exit 1; \
	 fi; \
	 bash "$$script"
endef

# Recursive recipes intentionally serialize stages, including under make -j.
bootstrap:
	@$(MAKE) --no-print-directory prerequisites
	@$(MAKE) --no-print-directory packages
	@$(MAKE) --no-print-directory repos
	@$(MAKE) --no-print-directory link
	@$(MAKE) --no-print-directory tools
	@$(MAKE) --no-print-directory plugins
	@$(MAKE) --no-print-directory config
	@$(MAKE) --no-print-directory hooks

sync:
	@$(MAKE) --no-print-directory packages
	@$(MAKE) --no-print-directory repos
	@$(MAKE) --no-print-directory link
	@$(MAKE) --no-print-directory tools
	@$(MAKE) --no-print-directory plugins

prerequisites:
	$(call run_platform_script,prerequisites)

packages:
	$(call run_platform_script,packages)

repos:
	@bash ./scripts/shared/repos.sh

link:
	@bash ./scripts/shared/link.sh $(DOTFILES_ARGS)

tools:
	@bash ./scripts/shared/tools.sh $(TOOLS_ARGS)

plugins:
	$(call run_platform_script,plugins)

# Preferences are optional; dotfile deployment belongs exclusively to link.
config:
	@if [ -f "./scripts/$$PROFILE/config.sh" ]; then \
	  bash "./scripts/$$PROFILE/config.sh"; \
	 else \
	  echo "No additional platform preferences for $$PROFILE."; \
	 fi

hooks:
	$(call run_platform_script,hooks)

aur:
	@test "$$PROFILE" = omarchy || \
	  { echo 'The aur target requires PROFILE=omarchy.' >&2; exit 1; }
	$(call run_platform_script,aur)

ghostty-shader:
	@test -n "$(REPO)" || \
	  { echo 'Usage: make ghostty-shader REPO=<git-url>' >&2; exit 1; }
	@bash ./scripts/ghostty-shader.sh "$(REPO)"
