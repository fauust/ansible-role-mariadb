venv:
	pip3 install -r requirements.txt

venv-upgrade:
	pip3 install -U -r requirements.txt

test:
	molecule test
