all:	initialize unit

clean:
	/bin/rm -r __pycache__ -f
	pipenv clean

docker:
	docker build -t mgmorey/stadium-ticket:latest .

initialize:
	./scripts/mysql.sh <sql/schema.sql

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

unit:	reset
	pipenv run ./test_tickets.py

.PHONY: all clean docker initialize pipenv reset run stress test unit
