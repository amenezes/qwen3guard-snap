SHELL := /bin/bash

# Always run `hf` via pipx to avoid relying on local `hf` installations.
hf := pipx run --spec "huggingface_hub[cli]" hf

SNAP_NAME ?= qwen3guard
ENGINE ?= cpu

# Default model: Qwen3Guard-Gen-0.6B Q4_K_M (from mradermacher).
# Checksums are PLACEHOLDER until first download; run `make download-models`
# then `sha256sum components/model-q4-k-m-0-6b-gguf/Qwen3Guard-Gen-0.6B-Q4_K_M.gguf`
# to obtain the real value and update this file.
GGUF_06B_REPO ?= mradermacher/Qwen3Guard-Gen-0.6B-GGUF
GGUF_06B_FILE ?= Qwen3Guard-Gen-0.6B.Q4_K_M.gguf
GGUF_06B_SHA256 ?= 2e73a1411746e6dbd8a71b4d22dc66369044283f433b81ed6e4006cab4af9859
MODEL_06B_DIR := components/model-q4-k-m-0-6b-gguf

# Additional variants: 4B and 8B (from mradermacher).
GGUF_4B_REPO ?= mradermacher/Qwen3Guard-Gen-4B-GGUF
GGUF_4B_FILE ?= Qwen3Guard-Gen-4B.Q4_K_M.gguf
GGUF_4B_SHA256 ?= PLACEHOLDER_4B
MODEL_4B_DIR := components/model-q4-k-m-4b-gguf

GGUF_8B_REPO ?= mradermacher/Qwen3Guard-Gen-8B-GGUF
GGUF_8B_FILE ?= Qwen3Guard-Gen-8B.Q4_K_M.gguf
GGUF_8B_SHA256 ?= PLACEHOLDER_8B
MODEL_8B_DIR := components/model-q4-k-m-8b-gguf

.PHONY: all help init init-all build install upload smoke-test install-deps init-submodules download-models download-extra-models verify-model verify-extra-models

all: help

#
# Main targets
#

help: ## Show this help message
	@echo "Usage: make <target>"
	@echo
	@echo "Targets:"
	@# List all targets with descriptions (lines starting with '##'):
	@grep -E '^[a-zA-Z0-9_-]+:.*## .*$$' $(MAKEFILE_LIST) | \
		sort | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  %-18s %s\n", $$1, $$2}'

init: init-submodules install-deps download-models verify-model ## Initialize the build environment (default 0.6B model only)

init-all: init-submodules install-deps download-models download-extra-models verify-model verify-extra-models ## Initialize with all model variants (0.6B, 4B, 8B)

build: ## Build the snap
	./dev/build.sh

install: ## Install the snap
	./dev/install.sh

upload: ## Upload the snap
	./dev/upload.sh

smoke-test: ## Run smoke tests (override with SNAP_NAME=... ENGINE=...)
	sudo ./dev/smoke-test.sh $(SNAP_NAME) $(ENGINE)

#
# Supporting targets
#

install-deps:
	@echo "Installing dependencies..."
	@# Ensure pipx is available for running the hf CLI.
	@command -v pipx >/dev/null 2>&1 || { \
		sudo apt-get update; \
		sudo apt-get install -y pipx; \
	}

init-submodules:
	@echo "Initializing submodules..."
	@if git submodule status | grep -q '^-'; then \
		git submodule update --init; \
	fi

download-models:
	@echo "Downloading Qwen3Guard-Gen-0.6B-Q4_K_M model weights..."
	$(hf) download $(GGUF_06B_REPO) $(GGUF_06B_FILE) \
		--local-dir $(MODEL_06B_DIR)

download-extra-models: ## Download 4B and 8B model variants
	@echo "Downloading Qwen3Guard-Gen-4B-Q4_K_M model weights..."
	$(hf) download $(GGUF_4B_REPO) $(GGUF_4B_FILE) \
		--local-dir $(MODEL_4B_DIR)
	@echo "Downloading Qwen3Guard-Gen-8B-Q4_K_M model weights..."
	$(hf) download $(GGUF_8B_REPO) $(GGUF_8B_FILE) \
		--local-dir $(MODEL_8B_DIR)

verify-model: ## Verify the 0.6B Q4_K_M GGUF checksum against the pinned sha256
	@echo "Verifying $(MODEL_06B_DIR)/$(GGUF_06B_FILE)..."
	@if [ ! -f "$(MODEL_06B_DIR)/$(GGUF_06B_FILE)" ]; then \
		echo "ERROR: $(MODEL_06B_DIR)/$(GGUF_06B_FILE) not found. Run 'make download-models' first." >&2; \
		exit 1; \
	fi
	@echo "$(GGUF_06B_SHA256)  $(MODEL_06B_DIR)/$(GGUF_06B_FILE)" | sha256sum --check --status \
		&& echo "OK: checksum matches" \
		|| { echo "ERROR: checksum mismatch (expected $(GGUF_06B_SHA256))" >&2; exit 1; }

verify-extra-models: ## Verify 4B and 8B GGUF checksums
	@echo "Verifying $(MODEL_4B_DIR)/$(GGUF_4B_FILE)..."
	@if [ ! -f "$(MODEL_4B_DIR)/$(GGUF_4B_FILE)" ]; then \
		echo "ERROR: $(MODEL_4B_DIR)/$(GGUF_4B_FILE) not found. Run 'make download-extra-models' first." >&2; \
		exit 1; \
	fi
	@echo "$(GGUF_4B_SHA256)  $(MODEL_4B_DIR)/$(GGUF_4B_FILE)" | sha256sum --check --status \
		&& echo "OK: 4B checksum matches" \
		|| { echo "ERROR: 4B checksum mismatch (expected $(GGUF_4B_SHA256))" >&2; exit 1; }
	@echo "Verifying $(MODEL_8B_DIR)/$(GGUF_8B_FILE)..."
	@if [ ! -f "$(MODEL_8B_DIR)/$(GGUF_8B_FILE)" ]; then \
		echo "ERROR: $(MODEL_8B_DIR)/$(GGUF_8B_FILE) not found. Run 'make download-extra-models' first." >&2; \
		exit 1; \
	fi
	@echo "$(GGUF_8B_SHA256)  $(MODEL_8B_DIR)/$(GGUF_8B_FILE)" | sha256sum --check --status \
		&& echo "OK: 8B checksum matches" \
		|| { echo "ERROR: 8B checksum mismatch (expected $(GGUF_8B_SHA256))" >&2; exit 1; }
