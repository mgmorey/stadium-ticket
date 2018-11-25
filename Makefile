SCRIPT_DIR = scripts

all:	Pipfile.lock requirements.txt

build:
	docker-compose up --build

run:
	docker-compose up

pipenv:
	$(SCRIPT_DIR)/pipenv.sh sync

stress:
	$(SCRIPT_DIR)/load-test.sh

traffic:
	$(SCRIPT_DIR)/app-test.sh

.PHONY: all build run pipenv stress traffic

Pipfile.lock:		Pipfile
	$(SCRIPT_DIR)/pipenv.sh update --dev

requirements.txt:	Pipfile
	$(SCRIPT_DIR)/pipenv.sh lock -r --dev >requirements.txt
	$(SCRIPT_DIR)/pipenv.sh lock -r >>requirements.txt
