all:	initialize unit

clean:
	/bin/rm -r __pycache__ -f
	pipenv clean

initialize: 
	pipenv install
	./mysql.sh <sql/schema.sql

reset: 
	./mysql.sh <sql/reset.sql

run:
	pipenv run ./app.py

stress:
	./load-test.sh

test:
	./test-app.sh

unit:	reset
	pipenv run ./test_tickets.py

update:
	pipenv update

.PHONY: all clean initialize reset run stress test unit update
