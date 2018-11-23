clean:
	pipenv clean

graph:
	pipenv graph

install: 
	./install-prerequisites.sh

remove:
	pipenv --rm

run:
	pipenv run ./app.py

reset:
	./mysql.sh <reset.sql

schema:
	./mysql.sh <schema.sql

test:
	cat schema.sql reset.sql | ./mysql.sh
	pipenv run ./test_tickets.py

update:
	pipenv update

.PHONY: clean graph install remove reset run schema test update
