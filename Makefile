all:	initialize unit

clean:
	cat sql/schema.sql sql/reset.sql | ./mysql.sh
	/bin/rm -r __pycache__ -f
	pipenv --rm

initialize: 
	./mysql.sh <sql/schema.sql
	./install-prerequisites.sh

load:
	./load-test.sh

run:	initialize
	pipenv run ./app.py

unit:	initialize
	pipenv run ./test_tickets.py

update:
	pipenv update

.PHONY: all clean initialize install load run unit update
