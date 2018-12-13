export DATABASE_DIALECT = $(shell . .env && printf $$DATABASE_DIALECT || true)

caches = $(shell find . -type d '(' -name '.venv*' -prune -o -name '*py*cache*' -print ')')
exclude = .git,__pycache__,.tox,.venv*
pycodestyle = $(python) -m pycodestyle
python = python3
script_dir = scripts
sql_dir = sql
unittest = $(python) -m unittest

all:	Makefile Pipfile.lock requirements.txt requirements-dev.txt .env unittest

build:	.env Pipfile.lock
	$(script_dir)/run.sh docker-compose up --build

check:
	$(script_dir)/run.sh $(pycodestyle) --exclude=$(exclude) .

clean:
	/bin/rm -rf $(caches)

client:
	$(script_dir)/app-test.sh

client-debug:
	$(script_dir)/app-test.sh -p 5001

debug:	reset
	$(script_dir)/run.sh flask run --port 5001

install:	Pipfile.lock .env
	$(script_dir)/install-app.sh

pipenv:	Pipfile
	$(script_dir)/install-pipenv.sh

reset:	schema
	$(script_dir)/sql.sh <$(sql_dir)/reset-$(DATABASE_DIALECT).sql

schema:
	$(script_dir)/sql.sh <$(sql_dir)/schema-$(DATABASE_DIALECT).sql

stress:
	$(script_dir)/load-test.sh

uninstall:
	$(script_dir)/uninstall-app.sh

unittest:	reset
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

.env:	.env-template
	$(script_dir)/configure-env.sh
