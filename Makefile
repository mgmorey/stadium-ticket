all:		database unittest

clean:
	/bin/rm -r __pycache__ -f
	pipenv clean

database:
	./scripts/mysql.sh <sql/schema.sql

docker:
	docker build -t mgmorey/stadium-ticket:latest .

pipenv:
	pipenv install

reset:
	./scripts/mysql.sh <sql/reset.sql

run:
	pipenv run ./app.py

stress:
	./load-test.sh

test:
	./app-test.sh

unittest:	reset
	pipenv run ./test_tickets.py

.PHONY: all clean database docker pipenv reset run stress test unittest
