export FLASK_APP := app.py
export FLASK_ENV := development
export PYTHONPATH := $(PWD)

all:	database reset unit

build:
	docker-compose up --build

clean:
	/bin/rm -rf __pycache__

database:
	scripts/mysql.sh <sql/schema.sql

debug:
	scripts/run.sh flask run

pip:
	pip install -r requirements.txt --user

reset:
	scripts/mysql.sh <sql/reset.sql

run:
	docker-compose up

stress:
	./load-test.sh

sync:
	scripts/sync.sh

test:
	./app-test.sh

unit:
	scripts/run.sh ./test_tickets.py

.PHONY: all build clean database debug pip reset run stress sync test unit
