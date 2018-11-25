export FLASK_APP := app.py
export FLASK_ENV := development
export PYTHONPATH := $(PWD)

all:	Pipfile.lock requirements.txt database reset sync

build:
	docker-compose up --build

clean:
	/bin/rm -rf __pycache__

database:
	scripts/mysql.sh <sql/schema.sql

debug:	reset
	scripts/run.sh flask run

pip:
	pip3 install -r requirements.txt --user

reset:	database
	scripts/mysql.sh <sql/reset.sql

run:
	docker-compose up

stress:
	scripts/load-test.sh

sync:
	scripts/sync.sh --dev

test:	reset
	scripts/run.sh python3 -m pytest

traffic:
	scripts/app-test.sh

Pipfile.lock:	Pipfile
	if [ -e $(HOME)/.local/bin/pipenv ]; then pipenv update; fi

requirements.txt:	Pipfile
	if [ -e $(HOME)/.local/bin/pipenv ]; then pipenv lock -r >requirements.txt; fi

.PHONY: all build clean database debug pip reset run stress sync test traffic
