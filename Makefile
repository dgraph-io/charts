SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')

ifeq ($(filter $(OS),darwin linux),)
$(error Unsupported OS: $(OS). Supported: darwin, linux)
endif

AUTO_INSTALL ?= false
export AUTO_INSTALL

DEPS := scripts/deps.sh

.DEFAULT_GOAL := help
# Package managers hold locks, so installs must not run in parallel.
.NOTPARALLEL:
.PHONY: help deps setup lint lint-all \
	deps-pm deps-pm-darwin deps-pm-linux \
	deps-helm deps-ct deps-yamllint deps-yamale deps-pre-commit deps-hook

help: ## Show this help message
	@echo ""
	@echo "Environment variables:"
	@echo "  AUTO_INSTALL=true   Install missing dependencies instead of only reporting them"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	    | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-18s %s\n", $$1, $$2}'
	@echo ""

deps: deps-helm deps-ct deps-yamllint deps-yamale deps-pre-commit deps-hook ## Check every dependency (AUTO_INSTALL=true installs the missing ones)

setup: ## Install every dependency and the pre-commit hook
	@$(MAKE) deps AUTO_INSTALL=true

lint: ## Lint the charts changed against main, as CI does
	ct lint --config ct.yaml

lint-all: ## Lint every chart
	ct lint --config ct.yaml --all

# Homebrew is the macOS package manager; Linux package managers ship with the OS.
deps-pm: deps-pm-$(OS)

deps-pm-darwin:
	@$(DEPS) brew

deps-pm-linux:
	@:

deps-helm: deps-pm
	@$(DEPS) helm

deps-ct: deps-pm
	@$(DEPS) ct

deps-yamllint: deps-pm
	@$(DEPS) yamllint

deps-yamale: deps-pm
	@$(DEPS) yamale

deps-pre-commit: deps-pm
	@$(DEPS) pre-commit

deps-hook: deps-pre-commit
	@$(DEPS) hook
