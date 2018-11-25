SCRIPT_DIR = scripts

all:	Pipfile.lock requirements.txt sync

build:	sync
	docker-compose up --build

run:	sync
	docker-compose up

sync:
	$(SCRIPT_DIR)/pipenv.sh sync --dev

.PHONY: all build run

Pipfile.lock:		Pipfile
	$(SCRIPT_DIR)/pipenv.sh update --dev

requirements.txt:	Pipfile
	$(SCRIPT_DIR)/pipenv.sh lock -r --dev >requirements.txt
	$(SCRIPT_DIR)/pipenv.sh lock -r >>requirements.txt
