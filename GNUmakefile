# GNUmakefile
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

APP_PORT := 5000

home := $(shell scripts/get-real-user-home)
tag := $(shell date +%Y%m%d%H%M)

all:	.env .update pycode pylint pytest

clean:	clean-app-caches

clean-app-caches:
	$(home)/bin/clean-up-app-caches

clean-virtualenv:
	$(home)/bin/clean-up-virtualenv

client:	.env
	clients/app-test

client-debug:	.env
	clients/app-test -h localhost -p $$(($(APP_PORT) + 1))

create-database:
	create-app-database || true
	run-app python3 -m app create-database

docker-build:	.env Dockerfile
	docker-app -t $(tag) build

docker-compose:	.env-api .env-mysql .env-postgres Dockerfile
	docker-compose up --build

docker-pull:
	docker-app pull

docker-push:	docker-build
	docker-app -t $(tag) push
	docker-app -l push

docker-run:	docker-build
	docker-app run

drop-database:
	run-app python3 -m app drop-database
	drop-app-database || true

get-configuration:
	get-configuration app.ini

get-parameters:
	run-app python3 -m app get-parameters

get-status:
	get-app-status

install:
	$(home)/bin/install-app

pycode:	.update
	$(home)/bin/run-app pycodestyle app tests

pylint:	.update
	$(home)/bin/run-app pylint app tests

pytest:	.update
	$(home)/bin/run-app pytest

pytest-all:	.update
	$(home)/bin/run-app pytest tests

realclean:	clean clean-virtualenv
	@/bin/rm -f .update

reinstall:	uninstall install

restart:
	$(home)/bin/restart-app

run:		.update create-database
	run-app flask run

run-debug:	.update create-database
	run-app flask run --port $$(($(APP_PORT) + 1))

scripts:
	scripts/install-utility-scripts

start:
	$(home)/bin/start-app

stop:
	$(home)/bin/stop-app

stress:	.env
	clients/load-test

superclean:	realclean uninstall-all

uninstall:	stop
	$(home)/bin/uninstall-app

uninstall-all:	stop
	$(home)/bin/uninstall-app -a

.PHONY:	all clean clean-app-caches clean-virtualenv client client-debug
.PHONY:	create-database docker-build docker-compose docker-pull docker-push
.PHONY:	docker-run docker-tag drop-database get-confiuguration get-parameters
.PHONY:	get-status install pycode pylint pytest pytest-all realclean restart
.PHONY:	run run-debug scripts start stop superclean uninstall uninstall-all

.env:		.env-template
	scripts/configure-env $@ $<

.env-api:	.env-template
	scripts/configure-env $@ $<

.env-mysql:	.env-template-mysql
	scripts/configure-env $@ $<

.env-postgres:	.env-template-postgres
	scripts/configure-env $@ $<

.update:	Pipfile
	$(home)/bin/refresh-virtualenv && touch $@ && scripts/chown-real-user $@
