all:	database unit

clean:
	/bin/rm -rf __pycache__
	pipenv clean || true

database:
	./scripts/mysql.sh <sql/schema.sql

docker:
	docker-compose up --build

pipenv:
	pipenv install

reset:
	./scripts/mysql.sh <sql/reset.sql

run:
	pipenv run ./app.py || ./app.py

stress:
	./load-test.sh

test:
	./app-test.sh

unit:	reset
	pipenv run ./test_tickets.py || ./test_tickets.py

.PHONY: all clean database docker pipenv reset run stress test unit
