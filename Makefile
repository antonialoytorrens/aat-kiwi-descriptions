#!/usr/bin/make -f
SHELL := /bin/bash

# Kiwi-NG Build System
# Usage: make build_<profile>
# Example: make build_x86_64_debian

# Configuration
BUILD_DIR := build
CONFIG_DIR := .
SOURCE_DIRS := tests

# Detect all available profiles from includes/profiles.xml
# (Simple grep to list them for help, though make will pattern match any string)
PROFILES := $(shell grep 'profile name="' includes/profiles.xml | cut -d'"' -f2)

.PHONY: all clean help download_extra test

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
	@echo "  download_extra - Download extra packages defined in Makefile.extra"
	@echo "  test           - Run all tests and linters"

download_extra:
	make -f Makefile.extra

clean:
	sudo rm -rf $(BUILD_DIR)
	make -f Makefile.extra clean
	@echo "Cleaning cache files..."
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@rm -rf htmlcov/ .coverage 2>/dev/null || true

# Dynamic Build Target
# Matches build_x86_64_debian, build_rpi_debian, etc.
build_%:
	@echo "Building profile: $*"
	mkdir -p $(BUILD_DIR)/$*
	sudo kiwi-ng --profile $* system build --description $(CONFIG_DIR) --target-dir $(BUILD_DIR)/$*

# Testing and Linting
test:
	@echo "=========================================="
	@echo "Running Comprehensive Test Suite"
	@echo "=========================================="
	@echo ""
	@echo "[1/9] Running pytest..."
	@pytest tests/ -v --cov=. --cov-report=term-missing || true
	@echo ""
	@echo "[2/9] Running ruff linter..."
	@ruff check $(SOURCE_DIRS) || true
	@echo ""
	@echo "[3/9] Running flake8..."
	@flake8 $(SOURCE_DIRS) || true
	@echo ""
	@echo "[4/9] Running pylint..."
	@pylint $(SOURCE_DIRS) || true
	@echo ""
	@echo "[5/9] Running mypy type checker..."
	@mypy $(SOURCE_DIRS) || true
	@echo ""
	@echo "[6/9] Running pyright type checker..."
	@pyright $(SOURCE_DIRS) || true
	@echo ""
	@echo "[7/9] Running bandit security scanner..."
	@bandit -r $(SOURCE_DIRS) -ll || true
	@echo ""
	@echo "[8/9] Checking code formatting (black)..."
	@black --check $(SOURCE_DIRS) || true
	@echo ""
	@echo "[9/9] Checking import sorting (isort)..."
	@isort --check-only $(SOURCE_DIRS) || true
	@echo ""
	@echo "=========================================="
	@echo "Test Suite Complete"
	@echo "=========================================="
