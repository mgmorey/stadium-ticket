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

script_dir = scripts

all:	.env .update pycode pylint pytest

build:	.env .update Dockerfile Pipfile-docker
	docker build -t stadium-ticket .

clean:	clean-app-caches clean-virtualenv

clean-app-caches:
	clean-app-caches

clean-virtualenv:
	clean-virtualenv

client:	.env
	$(script_dir)/app-test.sh

client-debug:	.env
	$(script_dir)/app-test.sh -h localhost -p 5001

compose:	.env .env-mysql .update Dockerfile Pipfile-docker
	docker-compose up --build

debug:		.update init-db
	run-app flask run --port 5001

drop-db:
	run-app python3 -m app drop-db

init-db:
	run-app python3 -m app init-db

pycode:	.update
	run-app pycodestyle app tests

pylint:	.update
	run-app pylint app tests

pytest:	.update
	run-app pytest tests

realclean:	clean clean-virtualenv
	@/bin/rm -f .update

scripts:
	$(script_dir)/install-utility-scripts.sh

status:
	get-app-status

stress:
	$(script_dir)/load-test.sh

.PHONY:	all build clean clean-app-caches clean-virtualenv client client-debug
.PHONY:	compose debug drop-db init-db pycode pylint pytest realclean scripts
.PHONY:	status stress

.env:		.env-template
	$(script_dir)/configure-env.sh $@ $<

.env-mysql:	.env-template-mysql
	$(script_dir)/configure-env.sh $@ $<

.update:	Pipfile Pipfile.lock
	refresh-virtualenv && touch $@

Makefile:	GNUmakefile
	ln -s $< $@

Pipfile-docker:	Pipfile
	@sed 's/^python_version = "3\.[0-9]*"/python_version = "3"/g' $< >$@
