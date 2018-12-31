script_dir = scripts

all:	.update pycode pylint pytest

build:	.env-docker .update
	$(script_dir)/run.sh docker-compose up --build

clean:
	$(script_dir)/clean-caches.sh

client:	.env
	$(script_dir)/app-test.sh

client-debug:	.env
	$(script_dir)/app-test.sh -h localhost -p 5001

debug:		.update init-db
	$(script_dir)/run.sh flask run --port 5001

install:	.env .update
	$(script_dir)/install-app.sh

pycode:	.update
	$(script_dir)/run.sh pycodestyle app

pylint:	.update
	$(script_dir)/run.sh pylint app

pytest:	.update init-db
	$(script_dir)/run.sh pytest tests

init-db:
	$(script_dir)/run.sh python3 -m app init-db

stress:
	$(script_dir)/load-test.sh

stress-debug:
	$(script_dir)/load-test.sh -h localhost -p 5001

uninstall:
	$(script_dir)/uninstall-app.sh

.PHONY: all build clean client client-debug debug init-db install
.PHONY: pycode pylint pytest init-db stress stress-debug uninstall

Makefile:	GNUmakefile
	ln -s GNUmakefile Makefile

.env:		.env-template
	$(script_dir)/configure-env.sh .env

.env-docker:	.env-template
	$(script_dir)/configure-env.sh .env-docker

.update:	Pipfile Pipfile.lock
	$(script_dir)/update-requirements.sh
