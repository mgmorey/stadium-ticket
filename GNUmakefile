script_dir = scripts
sql_dir = sql

all:	Pipfile.lock requirements-dev.txt requirements.txt sync pylint pytest

build:	Pipfile.lock .env-docker
	$(script_dir)/run.sh docker-compose up --build

clean:
	$(script_dir)/clean-caches.sh

client:	.env
	$(script_dir)/app-test.sh

client-debug:	.env
	$(script_dir)/app-test.sh -h localhost -p 5001

debug:	reset
	$(script_dir)/run.sh flask run --port 5001

install:	requirements-dev.txt requirements.txt .env
	$(script_dir)/install-app.sh

pipenv:	Pipfile
	$(script_dir)/pip-install-pipenv.sh

pycode:
	$(script_dir)/run.sh pycodestyle app

pylint:
	$(script_dir)/run.sh pylint app

pytest:	reset
	$(script_dir)/run.sh pytest

reset:	schema
	$(script_dir)/sql.sh reset

schema:
	$(script_dir)/sql.sh schema

stress:
	$(script_dir)/load-test.sh

sync:	Pipfile.lock requirements-dev.txt requirements.txt
	pipenv sync -d || true

uninstall:
	$(script_dir)/uninstall-app.sh

.PHONY: all build clean client client-debug debug install pipenv
.PHONY: pycode pylint pytest reset schema stress sync uninstall

Makefile:	GNUmakefile
	ln -s GNUmakefile Makefile

Pipfile.lock:	Pipfile
	pipenv update -d || true

requirements.txt:	Pipfile
	$(script_dir)/lock-requirements.sh requirements.txt

requirements-dev.txt:	Pipfile
	$(script_dir)/lock-requirements.sh -d requirements-dev.txt

.env:		.env-template
	$(script_dir)/configure-env.sh .env

.env-docker:	.env-template
	$(script_dir)/configure-env.sh .env-docker
