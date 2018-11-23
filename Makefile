all:	initialize unit

clean:
	/bin/rm -r __pycache__ -f
	pipenv clean

initialize: 
	cat sql/schema.sql sql/reset.sql | ./mysql.sh
	pipenv install

reset: 
	./mysql.sh <sql/reset.sql

run:
	pipenv run ./app.py

stress:
	./load-test.sh

test:
	./test-app.sh

unit:	initialize
	pipenv run ./test_tickets.py

update:
	pipenv update

.PHONY: all clean initialize reset run stress test unit update
