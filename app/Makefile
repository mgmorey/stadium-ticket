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

pytest:	reset
	$(SCRIPT_DIR)/run.sh python3 -m pytest

reset:	schema
	$(SCRIPT_DIR)/mysql.sh <$(SQL_DIR)/reset.sql

schema:
	$(SCRIPT_DIR)/mysql.sh <$(SQL_DIR)/schema.sql

stress: reset
	$(SCRIPT_DIR)/load-test.sh

traffic: reset
	$(SCRIPT_DIR)/app-test.sh

.PHONY: all clean debug pytest reset schema stress traffic
