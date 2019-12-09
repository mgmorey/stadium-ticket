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

clean:
	$(script_dir)/clean-app-caches.sh

clean-virtualenv:
	$(script_dir)/clean-virtualenv.sh

client:	.env
	$(script_dir)/app-test.sh

client-debug:	.env
	$(script_dir)/app-test.sh -h localhost -p 5001

compose:	.env .env-mysql .update Dockerfile Pipfile-docker
	docker-compose up --build

debug:		.update init-db
	$(script_dir)/run-app.sh flask run --port 5001

drop-db:
	$(script_dir)/run-app.sh python3 -m app drop-db

init-db:
	$(script_dir)/run-app.sh python3 -m app init-db

install:	.env .update
	$(script_dir)/install-app.sh

pycode:	.update
	$(script_dir)/run-app.sh pycodestyle app tests

pylint:	.update
	$(script_dir)/run-app.sh pylint app tests

pytest:	.update
	$(script_dir)/run-app.sh pytest tests

realclean:	clean clean-virtualenv
	@/bin/rm -f .update app/app/*.sqlite

restart:
	$(script_dir)/restart-app.sh

scripts:
	$(script_dir)/install-utility-scripts.sh

start:
	$(script_dir)/start-app.sh

status:
	$(script_dir)/get-app-status.sh

stop:
	$(script_dir)/stop-app.sh

stress:
	$(script_dir)/load-test.sh

uninstall:	stop
	$(script_dir)/uninstall-app.sh

uninstall-all:	stop
	$(script_dir)/uninstall-app.sh -a

.PHONY:	all build clean clean-virtualenv client client-debug compose debug
.PHONY:	drop-db init-db install pycode pylint pytest init-db realclean
.PHONY:	restart scripts start status stop stress uninstall uninstall-all

.env:		.env-template
	$(script_dir)/configure-env.sh $@ $<

.env-mysql:	.env-template-mysql
	$(script_dir)/configure-env.sh $@ $<

.update:	Pipfile Pipfile.lock
	$(script_dir)/refresh-virtualenv.sh && touch $@

Makefile:	GNUmakefile
	ln -s $< $@

Pipfile-docker:	Pipfile
	@sed 's/^python_version = "3\.[0-9]*"/python_version = "3"/g' $< >$@
