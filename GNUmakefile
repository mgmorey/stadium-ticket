SCRIPT_DIR = scripts

all:	Pipfile.lock requirements.txt

build:
	docker-compose up --build

check:
	$(SCRIPT_DIR)/pipenv.sh check

clean:
	@find . '(' -name __pycache__ -o -name .pytest_cache ')' -print | xargs /bin/rm -rf

install:	clean pipenv uwsgi
	$(SCRIPT_DIR)/install-app.sh

pip:
	pip3 install pip --upgrade --user
	pip3 install -r requirements.txt --user

pipenv:
	$(SCRIPT_DIR)/install-pipenv.sh

run:
	docker-compose up

stress:
	$(SCRIPT_DIR)/load-test.sh

traffic:
	$(SCRIPT_DIR)/app-test.sh

uninstall:
	$(SCRIPT_DIR)/uninstall-app.sh

uwsgi:
	install-packages uwsgi

.PHONY: all build check clean install pip pipenv run stress traffic uninstall uwgi

Pipfile.lock:	Pipfile
	$(SCRIPT_DIR)/pipenv.sh update --dev

requirements.txt:	Pipfile
	$(SCRIPT_DIR)/pipenv.sh lock -r --dev >requirements.txt
	$(SCRIPT_DIR)/pipenv.sh lock -r >>requirements.txt
