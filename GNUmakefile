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

home = $(shell if $(ismac); then $(macos); else $(posix); fi)
ismac = [ $$(uname -s) = Darwin ]
macos = printf "/Users/%s\n" $(user)
posix = getent passwd $(user) | awk -F: '{print $$6}'
user = "$${SUDO_USER-$${USER-$$LOGIN}}"

all:	.env .update pycode pylint pytest

clean:	clean-app-caches clean-virtualenv

clean-app-caches:
	clean-app-caches

clean-virtualenv:
	clean-virtualenv

client:	.env
	scripts/app-test.sh

client-debug:	.env
	scripts/app-test.sh -h localhost -p 5001

create-db:
	run-app python3 -m app create-db

docker-build:	.env .update Dockerfile Pipfile-docker
	docker build -t stadium-ticket .

docker-compose:	.env .env-mysql .update Dockerfile Pipfile-docker
	docker-compose up --build

drop-db:
	run-app python3 -m app drop-db

get-status:
	get-app-status

install:
	$(home)/bin/install-app

pycode:	.update
	run-app pycodestyle app tests

pylint:	.update
	run-app pylint app tests

pytest:	.update
	run-app pytest tests

realclean:	clean clean-virtualenv
	@/bin/rm -f .update

reinstall:	uninstall install

restart:
	$(home)/bin/restart-app

run-app:	.update create-db
	run-app flask run

run-debug:	.update create-db
	run-app flask run --port 5001

scripts:
	scripts/install-utility-scripts.sh

start:		install
	$(home)/bin/start-app

stop:
	$(home)/bin/stop-app

superclean:	realclean uninstall-all

uninstall:	stop
	$(home)/bin/uninstall-app

uninstall-all:	stop
	$(home)/bin/uninstall-app -a

.PHONY:	all clean clean-app-caches clean-virtualenv client client-debug
.PHONY:	create-db docker-build docker-compose drop-db get-status install
.PHONY:	pycode pylint pytest realclean restart run run-debug scripts
.PHONY:	start stop superclean uninstall uninstall-all

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
