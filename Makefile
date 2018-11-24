all:	database unit

build:
	docker-compose up --build

clean:
	/bin/rm -rf __pycache__
	@if pipenv >/dev/null; then pipenv clean; fi

database:
	./scripts/mysql.sh <sql/schema.sql

debug:
	@if pipenv >/dev/null; then pipenv run ./app.py; else ./app.py; fi

pip:
	pip install -r requirements.txt --user

reset:
	./scripts/mysql.sh <sql/reset.sql

run:
	docker-compose up

stress:
	./load-test.sh

test:
	./app-test.sh

unit:	reset
	@if pipenv >/dev/null; then pipenv sync; fi
	@if pipenv >/dev/null; then pipenv run ./test_tickets.py; else ./test_tickets.py; fi

.PHONY: all build clean database debug pip reset run stress test unit
