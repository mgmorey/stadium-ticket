all:	database unit

clean:
	/bin/rm -rf __pycache__
	@if pipenv >/dev/null; then pipenv clean; fi

database:
	./scripts/mysql.sh <sql/schema.sql

docker:
	docker-compose up --build

pip:
	pip install -r requirements.txt --user

pipenv:
	pipenv install

reset:
	./scripts/mysql.sh <sql/reset.sql

run:
	@if pipenv >/dev/null; then pipenv run ./app.py; else ./app.py; fi

stress:
	./load-test.sh

test:
	./app-test.sh

unit:	reset
	@if pipenv >/dev/null; then pipenv run ./test_tickets.py; else ./test_tickets.py; fi

.PHONY: all clean database docker pip pipenv reset run stress test unit
