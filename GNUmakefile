SCRIPT_DIR = scripts

all:	Pipfile.lock requirements.txt

build:
	docker-compose up --build

check:
	pipenv >/dev/null 2>&1 && pipenv check || true

clean:
	@find . '(' -name __pycache__ -o -name .pytest_cache ')' -print | xargs /bin/rm -rf

install:	clean pipenv
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

.PHONY: all build check clean install pip pipenv run stress traffic uninstall

Pipfile.lock:	Pipfile
	pipenv >/dev/null 2>&1 && pipenv update --dev || true

requirements.txt:	Pipfile
	pipenv >/dev/null 2>&1 && pipenv lock -r --dev >requirements.txt || true
	pipenv >/dev/null 2>&1 && pipenv lock -r >>requirements.txt || true
