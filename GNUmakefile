export FLASK_ENV := development
export PYTHONPATH := $(PWD)

SCRIPT_DIR = scripts
SQL_DIR = sql

all:	Pipfile.lock requirements.txt style update test

build:	.env Pipfile.lock
	docker-compose up --build

clean:
	@find . '(' -name __pycache__ -o -name .pytest_cache ')' -print | xargs /bin/rm -rf

debug:	reset
	$(SCRIPT_DIR)/run.sh flask run --port 5001

install:	.env Pipfile.lock
	$(SCRIPT_DIR)/install-app.sh

pip:	requirements.txt
	pip3 install pip --user
	pip3 install -r requirements.txt --user

pipenv:
	$(SCRIPT_DIR)/install-pipenv.sh
	pipenv install

run:
	docker-compose up

reset:	schema
	$(SCRIPT_DIR)/mysql.sh <$(SQL_DIR)/reset.sql

schema:
	$(SCRIPT_DIR)/mysql.sh <$(SQL_DIR)/schema.sql

stress:
	$(SCRIPT_DIR)/load-test.sh

style:
	pycodestyle *.py 2>/dev/null || true

test:	reset
	$(SCRIPT_DIR)/run.sh python3 -m unittest discover -vvv

traffic:
	$(SCRIPT_DIR)/app-test.sh

uninstall:
	$(SCRIPT_DIR)/uninstall-app.sh

update:
	pipenv update

.PHONY: all build clean debug install pip pipenv reset run schema stress style test traffic uninstall update


.env:	.env-template
	cp .env-template tmp$$$$ && $(EDITOR) tmp$$$$ && mv tmp$$$$ .env

Pipfile.lock:	Pipfile
	pipenv install || true

requirements.txt:	Pipfile
	pipenv lock -r >tmp$$$$ && mv -f tmp$$$$ requirements.txt || true
