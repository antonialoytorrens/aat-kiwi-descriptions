#!/usr/bin/make -f
SHELL := /bin/bash

# Kiwi-NG Build System
# Usage: make build_<profile>
# Example: make build_x86_64_debian

# Configuration
BUILD_DIR := build
CONFIG_DIR := .

# Detect all available profiles from includes/profiles.xml
# (Simple grep to list them for help, though make will pattern match any string)
PROFILES := $(shell grep 'profile name="' includes/profiles.xml | cut -d'"' -f2)

.PHONY: all clean help install_deps download_extra

all: help

help:
	@echo "Available Build Targets:"
	@echo "  make build_<profile>"
	@echo ""
	@echo "Available Profiles (detected):"
	@for p in $(PROFILES); do echo "  $$p"; done
	@echo ""
	@echo "Other targets:"
	@echo "  clean          - Remove build directory"
	@echo "  install_deps   - Install kiwi-ng and dependencies"
	@echo "  download_extra - Download extra packages defined in Makefile.extra"
	@echo "  test           - Run configuration tests"

install_deps:
	sudo apt-get update
	sudo apt-get install -y kiwi-ng qemu-user-static qemu-utils binfmt-support libxml2-utils shellcheck

download_extra:
	make -f Makefile.extra

clean:
	sudo rm -rf $(BUILD_DIR)
	make -f Makefile.extra clean

# Dynamic Build Target
# Matches build_x86_64_debian, build_rpi_debian, etc.
build_%:
	@echo "Building profile: $*"
	mkdir -p $(BUILD_DIR)/$*
	sudo kiwi-ng --profile $* system build --description $(CONFIG_DIR) --target-dir $(BUILD_DIR)/$*

# Testing
test:
	@echo "Running Tests..."
	@python3 -m unittest discover tests
