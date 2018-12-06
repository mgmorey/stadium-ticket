export FLASK_ENV := development
export PYTHONPATH := $(PWD)

PIP=pip3
PYCODESTYLE = pycodestyle --exclude=.git,__pycache__,.tox,.venv*
SCRIPT_DIR = scripts
SQL_DIR = sql

caches = $(shell find . -type d -name '*py*cache*' -print)

all:	Pipfile.lock requirements.txt requirements-dev.txt .env pystyle unittest

build:	.env Pipfile.lock
	docker-compose up --build

clean:
	@/bin/rm -rf $(caches)

client:
	$(SCRIPT_DIR)/app-test.sh

client-debug:
	$(SCRIPT_DIR)/app-test.sh 5001

debug:	reset
	$(SCRIPT_DIR)/run.sh flask run --port 5001

install:	Pipfile.lock .env
	$(SCRIPT_DIR)/install-app.sh

pipenv:	Pipfile
	$(SCRIPT_DIR)/install-pipenv.sh

pystyle:
	@$(PYCODESTYLE) . 2>/dev/null || true

reset:	schema
	$(SCRIPT_DIR)/sql.sh <$(SQL_DIR)/reset.sql

schema:
	$(SCRIPT_DIR)/sql.sh <$(SQL_DIR)/schema.sql

stress:
	$(SCRIPT_DIR)/load-test.sh

uninstall:
	$(SCRIPT_DIR)/uninstall-app.sh

unittest:	reset
	$(SCRIPT_DIR)/run.sh python3 -m unittest discover -vvv

update:	Pipfile.lock requirements.txt
	$(SCRIPT_DIR)/update-requirements.sh

.PHONY: all build clean client client-debug debug install pipenv
.PHONY: opystyle reset schema stress uninstall unittest update


Pipfile.lock:	Pipfile
	pipenv update -d || true

requirements.txt:	Pipfile
	$(SCRIPT_DIR)/lock-requirements.sh

requirements-dev.txt:	Pipfile
	$(SCRIPT_DIR)/lock-requirements.sh -d

.env:	.env-template
	$(SCRIPT_DIR)/configure-env.sh
