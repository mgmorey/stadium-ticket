export FLASK_APP := $(PWD)/app.py
export FLASK_ENV := development
export PYTHONPATH := $(PWD)

SCRIPT_DIR = ../scripts
SQL_DIR = ../sql

all:	schema reset

clean:
	/bin/rm -rf __pycache__ .pytest_cache

debug:	reset
	$(SCRIPT_DIR)/run.sh flask run

reset:	schema
	$(SCRIPT_DIR)/mysql.sh <$(SQL_DIR)/reset.sql

schema:
	$(SCRIPT_DIR)/mysql.sh <$(SQL_DIR)/schema.sql

test:	reset
	$(SCRIPT_DIR)/run.sh python3 -m pytest

.PHONY: all clean debug reset schema test
