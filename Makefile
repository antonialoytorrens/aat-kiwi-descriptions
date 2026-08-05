#!/usr/bin/make -f

# Usage: make <platform> DISTRO=<debian|alpine|pmos> TIER=<workstation|server> [RELEASE=<release>]
# Example: make pc_x86_64 DISTRO=debian TIER=workstation

SHELL := /bin/bash

# Static configuration
include settings.cfg

BUILD_DIR = build
CONFIG_DIR = .
DISTRO  ?=
TIER    ?= $(DEFAULT_TIER)
RELEASE ?= $(if $(filter debian,$(DISTRO)),$(DEBIAN_RELEASE),$(if $(filter alpine,$(DISTRO)),$(ALPINE_RELEASE),$(if $(filter pmos,$(DISTRO)),$(PMOS_RELEASE),)))

# Listings
PROFILES := $(shell grep 'profile name="' includes/profiles.xml | cut -d'"' -f2 | grep -E '_(debian|alpine|pmos)$$' | grep -v '^common_')
PLATFORMS := $(shell grep 'profile name="' includes/profiles.xml | cut -d'"' -f2 | grep -Ev '_(debian|alpine|pmos)$$' | grep -v '^common_' | grep -Ev '^(workstation|server)$$' | grep -Ev '^(debian|alpine|pmos)_')

# File listing
XML_FILES := $(shell find . -name "*.xml" -not -path "./$(BUILD_DIR)/*" -not -path "./bsp/*")
SHELL_SCRIPTS := config.sh post_bootstrap.sh pre_disk_sync.sh

.PHONY: all clean help lint format bsp $(PLATFORMS)

all: help

help:
	@echo "Usage: make <platform> DISTRO=<debian|alpine|pmos> TIER=<workstation|server> [RELEASE=<release>]"
	@echo "Example: make asus_tf101 DISTRO=debian TIER=workstation"
	@echo ""
	@echo "Available platforms and their distros:"
	@for p in $(PLATFORMS); do \
		distros=$$(printf '%s\n' $(PROFILES) | grep "^$${p}_" | sed "s/^$${p}_//" | tr '\n' ' '); \
		echo "  $$p: $$distros"; \
	done
	@echo ""
	@echo "RELEASE defaults per distro: debian=$(DEBIAN_RELEASE) alpine=$(ALPINE_RELEASE) pmos=$(PMOS_RELEASE)"
	@echo ""
	@echo "Other targets:"
	@echo "  clean          - Remove build directory"
	@echo "  lint           - Lint XML descriptions (xmllint) and shell scripts (shellcheck)"
	@echo "  format         - Reformat XML descriptions (xmllint --format) and shell scripts (shfmt -w) in place"
	@echo "  bsp            - Fetch/update device-specific tweaks (also runs automatically before a platform build)"

clean:
	sudo rm -rf $(BUILD_DIR)

# Board Support Packaging (can be empty for specific platforms)
bsp:
	@python3 scripts/fetch_bsp.py --repo $(BSP_REPO) --branch $(BSP_BRANCH)

# Build targets: make <platform> DISTRO=<debian|alpine|pmos> TIER=<workstation|server> [RELEASE=<release>]
$(PLATFORMS): bsp
	@[ -n "$(DISTRO)" ] || { echo "ERROR: DISTRO is required, e.g. make $@ DISTRO=debian"; exit 1; }; \
	printf '%s\n' $(SUPPORTED_TIERS) | grep -qx "$(TIER)" || { \
		echo "ERROR: TIER must be one of: $(SUPPORTED_TIERS), got '$(TIER)'"; exit 1; \
	}; \
	profile="$@_$(DISTRO)"; \
	printf '%s\n' $(PROFILES) | grep -qx "$$profile" || { \
		echo "ERROR: no such profile '$$profile'. Valid distros for $@: $$(printf '%s\n' $(PROFILES) | grep "^$@_" | sed "s/^$@_//" | tr '\n' ' ')"; \
		exit 1; \
	}; \
	python3 scripts/apply_bsp.py --device "$@" --distribution "$(DISTRO)" --release "$(RELEASE)"; \
	build_profile="$$profile,$(TIER),$(DISTRO)_$(RELEASE)"; \
	outdir="$(BUILD_DIR)/$${profile}_$(TIER)_$(RELEASE)"; \
	echo "Building profile: $$build_profile"; \
	mkdir -p "$$outdir"; \
	sudo kiwi-ng --profile "$$build_profile" system build --description $(CONFIG_DIR) --target-dir "$$outdir"

lint:
	@echo "Linting XML descriptions (xmllint)..."
	@for f in $(XML_FILES); do xmllint --noout "$$f" || exit 1; done
	@echo "Linting XML ordering (common_* profiles first + alphabetical, include from= alphabetical)..."
	@python3 scripts/lint_profile_order.py $(XML_FILES)
	@echo "Linting shell scripts (shellcheck)..."
	@shellcheck $(SHELL_SCRIPTS)
	@echo "Lint OK"

format:
	@echo "Formatting XML descriptions (xmllint --format)..."
	@for f in $(XML_FILES); do xmllint --format "$$f" -o "$$f"; done
	@echo "Formatting shell scripts (shfmt -w)..."
	@shfmt -w $(SHELL_SCRIPTS)
