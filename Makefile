VENV_DIR := .venv
SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

help:
	@grep -E '^[a-zA-Z1-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }'

install: ## Install all necessary tools
	$(MAKE) \
		venv \
		install-pip-packages
	@echo -e "\n--> You should now activate the python3 venv with:"
	@echo -e "source $(VENV_DIR)/bin/activate"

venv: ## Create python3 venv if it does not exists
	[[ -d $(VENV_DIR) ]] || $(shell command -v python3) -m venv $(VENV_DIR)

install-pip-packages: ## Install python3 requirements
	$(info --> Install requirements via `pip3`)
	@( \
			source $(VENV_DIR)/bin/activate; \
			pip3 install -r requirements.txt; \
	)

upgrade-pip-packages: ## Upgrade python3 requirements
	$(shell command -v pip3) install -U -r requirements.txt

clean: ## Clean venv
	[[ ! -d $(VENV_DIR) ]] || rm -rf $(VENV_DIR)
