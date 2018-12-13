export DATABASE_DIALECT = $(shell . .env && printf $$DATABASE_DIALECT)

caches = $(shell $(find))
exclude = .git,__pycache__,.tox,.venv*
find = find . -type d \( $(prune) -o $(print) \)
print = -name '*py*cache*' -print
prune = -name '.venv*' -prune
pycodestyle = $(python) -m pycodestyle
python = python3
script_dir = scripts
sql_dir = sql
unittest = $(python) -m unittest

all:	Pipfile.lock requirements.txt requirements-dev.txt .env unittest

build:	.env-docker Pipfile.lock
	$(script_dir)/run.sh docker-compose up --build

check:
	$(script_dir)/run.sh $(pycodestyle) --exclude=$(exclude) .

clean:
	/bin/rm -rf $(caches)

client:
	$(script_dir)/app-test.sh

client-debug:
	$(script_dir)/app-test.sh -p 5001

debug:	.env reset
	$(script_dir)/run.sh flask run --port 5001

install:	Pipfile.lock .env
	$(script_dir)/install-app.sh

pipenv:	Pipfile
	$(script_dir)/install-pipenv.sh

reset:	.env schema
	$(script_dir)/sql.sh <$(sql_dir)/reset-$(DATABASE_DIALECT).sql

schema:	.emv
	$(script_dir)/sql.sh <$(sql_dir)/schema-$(DATABASE_DIALECT).sql

stress:
	$(script_dir)/load-test.sh

uninstall:
	$(script_dir)/uninstall-app.sh

unittest:	.env reset
	$(script_dir)/run.sh $(unittest) discover

update:	Pipfile.lock requirements.txt
	$(script_dir)/update-requirements.sh

.PHONY: all build check clean client client-debug debug install 
.PHONY: pipenv reset schema stress uninstall unittest update

Makefile:	GNUmakefile
	ln -s GNUmakefile Makefile

Pipfile.lock:	Pipfile
	pipenv update -d || true

requirements.txt:	Pipfile
	$(script_dir)/lock-requirements.sh

requirements-dev.txt:	Pipfile
	$(script_dir)/lock-requirements.sh -d

.env:		.env-template
	$(script_dir)/configure-env.sh .env

.env-docker:	.env-template
	$(script_dir)/configure-env.sh .env-docker
