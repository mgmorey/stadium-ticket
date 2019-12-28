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

bin = $(home)/bin
home = $(shell if $(ismac); then $(macos); else $(posix); fi)
ismac = [ $$(uname -s) = Darwin ]
macos = printf "/Users/%s\n" $(user)
posix = getent passwd $(user) | awk -F: '{print $$6}'
user = "$${SUDO_USER-$${USER-$$LOGIN}}"

all:	.env .update pycode pytest

clean:	clean-app-caches clean-virtualenv

clean-app-caches:
	$(bin)/clean-app-caches

clean-virtualenv:
	$(bin)/clean-virtualenv

client:	.env
	clients/app-test

client-debug:	.env
	clients/app-test -h localhost -p 5001

create-database:
	run-app python3 -m app create-database

docker-build:	.env .update Dockerfile
	docker build -t stadium-ticket .

docker-compose:	.env .env-mysql .update Dockerfile
	docker-compose up --build

drop-database:
	run-app python3 -m app drop-database

get-status:
	get-app-status

install:
	$(bin)/install-app

pycode:	.update
	run-app pycodestyle app tests

pylint:	.update
	run-app pylint app tests

pytest:	.update
	run-app pytest --pylint tests/unit

realclean:	clean clean-virtualenv
	@/bin/rm -f .update

reinstall:	uninstall install

restart:
	$(bin)/restart-app

run-app:	.update create-database
	run-app flask run

run-debug:	.update create-database
	run-app flask run --port 5001

scripts:
	scripts/install-utility-scripts

start:
	$(bin)/start-app

stop:
	$(bin)/stop-app

stress:	.env
	clients/load-test

superclean:	realclean uninstall-all

uninstall:	stop
	$(bin)/uninstall-app

uninstall-all:	stop
	$(bin)/uninstall-app -a

.PHONY:	all clean clean-app-caches clean-virtualenv client client-debug
.PHONY:	create-database docker-build docker-compose drop-database get-status
.PHONY:	install pycode pylint pytest realclean restart run run-debug scripts
.PHONY:	start stop superclean uninstall uninstall-all

.env:		.env-template
	scripts/configure-env $@ $<

.env-mysql:	.env-template-mysql
	scripts/configure-env $@ $<

.update:	Pipfile Pipfile.lock
	$(bin)/refresh-virtualenv && touch $@
