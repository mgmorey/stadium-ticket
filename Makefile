all:	initialize unit

clean:
	/bin/rm -r __pycache__ -f
	pipenv clean

initialize: 
	./mysql.sh <sql/schema.sql

pipenv: 
	pipenv install

reset: 
	./mysql.sh <sql/reset.sql

run:
	pipenv run ./app.py

stress:
	./load-test.sh

test:
	./app-test.sh

unit:	reset
	pipenv run ./test_tickets.py

update:
	pipenv update

.PHONY: all clean initialize pipenv reset run stress test unit update
