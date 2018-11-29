export FLASK_APP := $(PWD)/app.py
export FLASK_ENV := development
export PYTHONPATH := $(PWD)

SCRIPT_DIR = ../scripts
SQL_DIR = ../sql

all:	schema reset

clean:
	find . '(' -name __pycache__ -o -name .pytest_cache ')' -print | xargs /bin/rm -rf

debug:	pipenv reset
	$(SCRIPT_DIR)/run.sh flask run

pipenv:
	pipenv >/dev/null 2>&1 && pipenv sync --dev || true

reset:	schema
	$(SCRIPT_DIR)/mysql.sh <$(SQL_DIR)/reset.sql

schema:
	$(SCRIPT_DIR)/mysql.sh <$(SQL_DIR)/schema.sql

test:	pipenv reset
	$(SCRIPT_DIR)/run.sh py.test

.PHONY: all clean debug reset schema test
