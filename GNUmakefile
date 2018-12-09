export FLASK_ENV := development
export PYTHONPATH := $(PWD)

pystyle = $(python) -m pycodestyle --exclude=.git,__pycache__,.tox,.venv*
python = python3
script_dir = scripts
sql_dir = sql

caches = $(shell find . -type d -name '*py*cache*' -print)

all:	Pipfile.lock requirements.txt requirements-dev.txt .env check unittest

build:	.env Pipfile.lock
	pip3 install --upgrade --user pip
	pip3 install --upgrade --user docker-compose
	docker-compose up --build

check:
	@$(pystyle) . 2>/dev/null || true

clean:
	@/bin/rm -rf $(caches)

client:
	$(script_dir)/app-test.sh

client-debug:
	$(script_dir)/app-test.sh 5001

debug:	reset
	$(script_dir)/run.sh flask run --port 5001

install:	Pipfile.lock .env
	$(script_dir)/install-app.sh

pipenv:	Pipfile
	$(script_dir)/install-pipenv.sh

reset:	schema
	$(script_dir)/sql.sh <$(sql_dir)/reset.sql

schema:
	$(script_dir)/sql.sh <$(sql_dir)/schema.sql

stress:
	$(script_dir)/load-test.sh

uninstall:
	$(script_dir)/uninstall-app.sh

unittest:	reset
	$(script_dir)/run.sh python3 -m unittest discover -vvv

update:	Pipfile.lock requirements.txt
	$(script_dir)/update-requirements.sh

.PHONY: all build check clean client client-debug debug install 
.PHONY: pipenv reset schema stress uninstall unittest update

Pipfile.lock:	Pipfile
	pipenv update -d || true

requirements.txt:	Pipfile
	$(script_dir)/lock-requirements.sh

requirements-dev.txt:	Pipfile
	$(script_dir)/lock-requirements.sh -d

.env:	.env-template
	$(script_dir)/configure-env.sh
