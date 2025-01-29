VENV_DIR := .venv
VENDOR_DIR := .vendor
SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

help:
	@grep -E '^[a-zA-Z1-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }'

venv: ## Create python3 venv if it does not exists
	[[ -d $(VENV_DIR) ]] || uv venv $(VENV_DIR)

install: ## Install all necessary tools
	$(MAKE) venv
	$(MAKE) install-pip-packages
	$(MAKE) install-galaxy
	@echo -e "\n--> You should now activate the python3 venv with:"
	@echo -e "source $(VENV_DIR)/bin/activate"

install-pip-packages: ## Install python3 requirements
	$(info --> Install requirements via `uv pip`)
	@( \
			source $(VENV_DIR)/bin/activate; \
			uv pip install -r requirements.txt; \
	)

install-galaxy: ## Install galaxy requirements
	$(info --> Install galaxy requirements)
	ansible-galaxy collection install -r requirements.yml --force -p $(VENDOR_DIR)/collections

install-pre-commit: ## Install pre-commit tool
	$(info --> Install pre-commit tool via `pip3`)
	uv pip install pre-commit

pre-commit-run: ## Run pre-commit hooks
	$(info --> run pre-commit on changed files (pre-commit run))
	pre-commit run --color=always

pre-commit-run-all: ## Run pre-commit on the whole repository
	$(info --> run pre-commit on the whole repo (pre-commit run -a))
	pre-commit run -a --color=always

clean: ## Clean venv
	[[ ! -d $(VENV_DIR) ]] || rm -rf $(VENV_DIR)
	[[ ! -d $(VENDOR_DIR) ]] || rm -rf $(VENDOR_DIR)
