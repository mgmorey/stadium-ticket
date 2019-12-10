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

home_dir = $(shell get-sudo-user-home)

all:	.env .update pycode pylint pytest

build:	.env .update Dockerfile Pipfile-docker
	docker build -t stadium-ticket .

clean:	clean-app-caches clean-virtualenv

clean-app-caches:
	clean-app-caches

clean-virtualenv:
	clean-virtualenv

client:	.env
	scripts/app-test.sh

client-debug:	.env
	scripts/app-test.sh -h localhost -p 5001

compose:	.env .env-mysql .update Dockerfile Pipfile-docker
	docker-compose up --build

drop-db:
	run-app python3 -m app drop-db

get-status:
	get-app-status

create-db:
	run-app python3 -m app create-db

install:
	$(home_dir)/bin/install-app

pycode:	.update
	run-app pycodestyle app tests

pylint:	.update
	run-app pylint app tests

pytest:	.update
	run-app pytest tests

realclean:	clean clean-virtualenv
	@/bin/rm -f .update

restart:
	$(home_dir)/bin/restart-app

run-app:	.update create-db
	run-app flask run

run-debug:	.update create-db
	run-app flask run --port 5001

scripts:
	scripts/install-utility-scripts.sh

start:		install
	$(home_dir)/bin/start-app

stop:
	$(home_dir)/bin/stop-app

uninstall:	stop
	$(home_dir)/bin/install-app

.PHONY:	all build clean clean-app-caches clean-virtualenv client client-debug
.PHONY:	compose create-db drop-db get-status install pycode pylint pytest
.PHONY:	realclean restart run run-debug scripts start stop uninstall

.env:		.env-template
	scripts/configure-env.sh $@ $<

.env-mysql:	.env-template-mysql
	scripts/configure-env.sh $@ $<

.update:	Pipfile Pipfile.lock
	refresh-virtualenv && touch $@

Makefile:	GNUmakefile
	ln -s $< $@

Pipfile-docker:	Pipfile
	@sed 's/^python_version = "3\.[0-9]*"/python_version = "3"/g' $< >$@
