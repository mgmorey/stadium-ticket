export FLASK_ENV := development
export PYTHONPATH := $(PWD)

PIP=pip3
SCRIPT_DIR = scripts
SQL_DIR = sql

caches = $(shell find . -type d -name '*py*cache' -print)
modules = $(shell find . -type f -name '*.py' -print)

all:	Pipfile.lock requirements.txt .env pystyle unittest

build:	.env Pipfile.lock
	docker-compose up --build

clean:
	@/bin/rm -rf $(caches)

client:
	$(SCRIPT_DIR)/app-test.sh

debug:	reset
	$(SCRIPT_DIR)/run.sh flask run --port 5001

install:	Pipfile.lock .env
	$(SCRIPT_DIR)/install-app.sh

pipenv:	Pipfile
	$(SCRIPT_DIR)/install-pipenv.sh

pystyle:
	@which pycodestyle >/dev/null 2>&1 && pycodestyle $(modules) || true

reset:	schema
	$(SCRIPT_DIR)/sql.sh <$(SQL_DIR)/reset.sql

schema:
	$(SCRIPT_DIR)/sql.sh <$(SQL_DIR)/schema.sql

stress:
	$(SCRIPT_DIR)/load-test.sh

uninstall:
	$(SCRIPT_DIR)/uninstall-app.sh

unittest:	update reset
	$(SCRIPT_DIR)/run.sh python3 -m unittest discover -vvv

update:	Pipfile.lock requirements.txt
	$(SCRIPT_DIR)/update-dependencies.sh

.PHONY: all build clean client debug install pipenv pystyle 
.PHONY: reset schema stress uninstall unittest update


Pipfile.lock:	Pipfile
	pipenv lock -d

requirements.txt:	Pipfile
	$(SCRIPT_DIR)/lock-requirements.sh

.env:	.env-template
	$(SCRIPT_DIR)/configure-app.sh
