clean:
	pipenv clean

graph:
	pipenv graph

install:
	pipenv install

reset:
	./mysql.sh <reset.sql

schema:
	./mysql.sh <schema.sql

start:
	pipenv run ./app.py

unittest:
	pipenv run ./test_tickets.py

update:
	pipenv update

.PHONY: clean graph install reset schema start unittest update
