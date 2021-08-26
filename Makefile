VENV_DIR := .venv
SHELL := bash
.DEFAULT_GOAL := help
.ONESHELL:

help:
	@grep '^#?.*' $(MAKEFILE_LIST) \
	| awk -F ':' '{ $$1 = substr($$1, 4); printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }'

$(VENV_DIR):
	$(shell command -v python3) -m venv $(VENV_DIR)

#? install: Install all necessary tools
install: install-pip-packages
	@$(info --> You should now activate the python3 venv with:)
	@$(info source $(VENV_DIR)/bin/activate)

#? install-pip-packages: Install python3 requirements
install-pip-packages: $(VENV_DIR)
	@$(info --> Install requirements via `pip3`)
	@source $(VENV_DIR)/bin/activate
	@pip3 install -r requirements.txt

#? upgrade-pip-packages: Upgrade python3 requirements
upgrade-pip-packages: $(VENV_DIR)
	@source $(VENV_DIR)/bin/activate
	@pip3 install --upgrade -r requirements.txt

#? clean: Clean venv
clean:
	[[ ! -d $(VENV_DIR) ]] || rm -rf $(VENV_DIR)
