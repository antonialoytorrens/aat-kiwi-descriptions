#!/usr/bin/make -f

SHELL := /bin/bash

include settings.cfg

# DISTROS, sourced from keys of RELEASES in settings.cfg
empty :=
space := $(empty) $(empty)
DISTROS := $(foreach r,$(RELEASES),$(word 1,$(subst :, ,$(r))))
DISTRO_ALT := $(subst $(space),|,$(DISTROS))

# Listings
PROFILES := $(shell grep 'profile name="' includes/profiles.xml | cut -d'"' -f2 | grep -E '_($(DISTRO_ALT))$$' | grep -v '^common_')
PLATFORMS := $(shell grep 'profile name="' includes/profiles.xml | cut -d'"' -f2 | grep -Ev '_($(DISTRO_ALT))$$' | grep -v '^common_' | grep -Ev '^(workstation|server)$$' | grep -Ev '^($(DISTRO_ALT))_')

BUILD_DIR = build
CONFIG_DIR = .
DISTRO  ?=
TIER    ?= $(DEFAULT_TIER)
RELEASE ?=
SUDO    := $(shell [ "$$(id -u)" = 0 ] && echo "" || echo "sudo")
COMPOSE := docker compose
SERVICE := builder

# File listing
XML_FILES := $(shell find . \( -path "./$(BUILD_DIR)" -o -path "./bsp" \) -prune -o -name "*.xml" -print)
SHELL_SCRIPTS := config.sh post_bootstrap.sh pre_disk_sync.sh

# Docker-wrapped equivalents of the host-direct targets below, e.g. docker-pc-x86_64
DOCKER_TARGETS := $(addprefix docker-,$(PLATFORMS) lint format clean bsp-pull)

.PHONY: all clean help lint format bsp-pull docker-build docker-shell docker-down $(PLATFORMS) $(DOCKER_TARGETS)

all: help

help:
	@echo "Usage: make <platform> DISTRO=<$(DISTRO_ALT)> TIER=<workstation|server> [RELEASE=<release>]"
	@echo "Example (native, on host):     make pc-x86_64 DISTRO=debian TIER=workstation"
	@echo "Example (isolated, in Docker): make docker-pc-x86_64 DISTRO=debian TIER=workstation"
	@echo ""
	@echo "Available platforms and their distros:"
	@for p in $(PLATFORMS); do \
		distros=$$(printf '%s\n' $(PROFILES) | grep "^$${p}_" | sed "s/^$${p}_//" | tr '\n' ' '); \
		echo "  $$p: $$distros"; \
	done
	@echo ""
	@echo "Permitted releases per distro (first is the default):"
	@for dr in $(RELEASES); do \
		d=$${dr%%:*}; r=$${dr#*:}; \
		echo "  $$d: $${r//,/ }"; \
	done
	@echo ""
	@echo "Other targets:"
	@echo "  clean          - Remove build directory"
	@echo "  lint           - Lint XML descriptions (xmllint) and shell scripts (shellcheck)"
	@echo "  format         - Reformat XML descriptions (xmllint --format) and shell scripts (shfmt -w) in place"
	@echo "  bsp-pull       - Fetch/update device-specific tweaks (on demand; not run automatically)"
	@echo ""
	@echo "Docker targets (isolated builds via docker compose):"
	@echo "  docker-build       - Build (or rebuild) the builder image"
	@echo "  docker-shell       - Open an interactive shell in the builder container"
	@echo "  docker-down        - Remove containers and the kiwi package-cache volume"
	@echo "  docker-<target>    - Run <target> (a platform, lint, format, clean, or bsp-pull) inside the container"
	@echo ""
	@echo "  Foreign-arch platforms (e.g. minix-neox8h, odroid-u3, asus-tf101) run"
	@echo "  the builder container itself under QEMU emulation, matching the"
	@echo "  platform's arch. This requires the Docker host to have QEMU binfmt_misc"
	@echo "  interpreters registered once, e.g.:"
	@echo "    docker run --privileged --rm tonistiigi/binfmt --install all"

clean:
	$(SUDO) rm -rf /var/cache/kiwi/*
	$(SUDO) rm -rf $(BUILD_DIR)

# Board Support Packaging (can be empty for specific platforms); run on demand, not automatically
bsp-pull:
	@python3 scripts/fetch_bsp.py --repo $(BSP_REPO) --branch $(BSP_BRANCH)

# Build targets: make <platform> DISTRO=<distro> TIER=<workstation|server> [RELEASE=<release>]
$(PLATFORMS):
	@[ -n "$(DISTRO)" ] || { echo "ERROR: DISTRO is required"; exit 1; }; \
	releases=$$(printf '%s\n' $(RELEASES) | awk -F: -v d="$(DISTRO)" '$$1==d{print $$2}' | tr ',' ' '); \
	[ -n "$$releases" ] || { echo "ERROR: DISTRO must be one of: $(DISTROS), got '$(DISTRO)'"; exit 1; }; \
	printf '%s\n' $(SUPPORTED_TIERS) | grep -qx "$(TIER)" || { \
		echo "ERROR: TIER must be one of: $(SUPPORTED_TIERS), got '$(TIER)'"; exit 1; \
	}; \
	release="$(RELEASE)"; [ -n "$$release" ] || release=$$(printf '%s\n' $$releases | head -1); \
	printf '%s\n' $$releases | grep -qx "$$release" || { \
		echo "ERROR: RELEASE must be one of: $$releases for DISTRO=$(DISTRO), got '$$release'"; exit 1; \
	}; \
	profile="$@_$(DISTRO)"; \
	printf '%s\n' $(PROFILES) | grep -qx "$$profile" || { \
		echo "ERROR: no such profile '$$profile'. Valid distros for $@: $$(printf '%s\n' $(PROFILES) | grep "^$@_" | sed "s/^$@_//" | tr '\n' ' ')"; \
		exit 1; \
	}; \
	python3 scripts/apply_bsp.py --device "$@" --distribution "$(DISTRO)" --release "$$release"; \
	build_profile="$$profile,$(TIER),$(DISTRO)_$$release"; \
	outdir="$(BUILD_DIR)/$${profile}_$(TIER)_$$release"; \
	arch=$$(grep "name=\"$@\"" includes/profiles.xml | grep -o 'arch="[^"]*"' | cut -d'"' -f2); \
	echo "Building profile: $$build_profile (arch: $${arch:-host})"; \
	mkdir -p "$$outdir"; \
	# This directory shall be created, otherwise debian keyring fails \
	$(SUDO) mkdir -p /var/cache/kiwi/apt-get/trusted.gpg.d; \
	$(SUDO) kiwi-ng $${arch:+--target-arch "$$arch"} --profile "$$profile" --profile "$(TIER)" --profile "$(DISTRO)_$$release" system build --description $(CONFIG_DIR) --target-dir "$$outdir"

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

docker-build:
	$(COMPOSE) build

docker-shell:
	$(COMPOSE) run --rm $(SERVICE) bash

docker-down:
	$(COMPOSE) down -v

# Docker-wrapped equivalents: make docker-<platform|lint|format|clean|bsp-pull>
$(DOCKER_TARGETS):
	@target=$(@:docker-%=%); \
	arch=$$(grep "name=\"$$target\"" includes/profiles.xml | grep -o 'arch="[^"]*"' | cut -d'"' -f2); \
	case "$$arch" in \
		x86_64) platform=linux/amd64 ;; \
		i686|i586) platform=linux/386 ;; \
		armv7l) platform=linux/arm/v7 ;; \
		aarch64) platform=linux/arm64 ;; \
		*) platform=linux/amd64 ;; \
	esac; \
	DOCKER_PLATFORM=$$platform $(COMPOSE) run --rm $(SERVICE) make $$target \
		$(if $(DISTRO),DISTRO=$(DISTRO)) \
		$(if $(TIER),TIER=$(TIER)) \
		$(if $(RELEASE),RELEASE=$(RELEASE))
