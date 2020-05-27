venv:
	pip3 install -r requirements.txt

venv_upgrade:
	for i in $$(cat requirements.txt|cut -d "=" -f1); do pip3 install $$i -U; done

test:
	molecule test
