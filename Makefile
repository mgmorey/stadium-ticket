clean:
	pipenv clean

graph:
	pipenv graph

install:
	pipenv install

remove:
	pipenv --rm

run:
	pipenv run ./app.py

reset:
	./mysql.sh <reset.sql

schema:
	./mysql.sh <schema.sql

test:
	pipenv run ./test_tickets.py

update:
	pipenv update

.PHONY: clean graph install remove reset run schema test update
