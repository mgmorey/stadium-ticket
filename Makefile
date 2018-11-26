SCRIPT_DIR = scripts

all:	Pipfile.lock requirements.txt

build:
	docker-compose up --build

check:
	$(SCRIPT_DIR)/pipenv.sh check

pip:
	pip3 install -r requirements.txt --user

pipenv:
	$(SCRIPT_DIR)/pipenv.sh sync

run:
	docker-compose up

stress:
	$(SCRIPT_DIR)/load-test.sh

traffic:
	$(SCRIPT_DIR)/app-test.sh

.PHONY: all build check pip pipenv run stress traffic

Pipfile.lock:		Pipfile
	$(SCRIPT_DIR)/pipenv.sh update --dev

requirements.txt:	Pipfile
	$(SCRIPT_DIR)/pipenv.sh lock -r --dev >requirements.txt
	$(SCRIPT_DIR)/pipenv.sh lock -r >>requirements.txt
