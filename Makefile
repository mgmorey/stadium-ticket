clean:
	pipenv clean

graph:
	pipenv graph

initialize: 
	cat schema.sql reset.sql | ./mysql.sh

install: 
	./install-prerequisites.sh

load:
	./load-test.sh

remove:
	pipenv --rm

run:	initialize
	pipenv run ./app.py

test:
	./test-app.sh

unit:	initialize
	pipenv run ./test_tickets.py

update:
	pipenv update

.PHONY: clean graph install remove reset run schema test update
