export FLASK_APP := $(PWD)/app.py
export FLASK_ENV := development
export PYTHONPATH := $(PWD)

SCRIPT_DIR = ../scripts
SQL_DIR = ../sql

all:	style test

clean:
	@find . '(' -name __pycache__ -o -name .pytest_cache ')' -print | xargs /bin/rm -rf

debug:	reset
	$(SCRIPT_DIR)/run.sh flask run

reset:	schema
	$(SCRIPT_DIR)/mysql.sh <$(SQL_DIR)/reset.sql

schema:
	$(SCRIPT_DIR)/mysql.sh <$(SQL_DIR)/schema.sql

style:
	pycodestyle *.py

test:	reset
	$(SCRIPT_DIR)/run.sh python3 -m unittest discover -vvv

.PHONY: all clean debug reset schema style test
