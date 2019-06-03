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

build:	.env .env-mysql .update
	docker-compose up --build

clean:
	$(script_dir)/clean-caches.sh

clean-venvs:
	$(script_dir)/clean-virtualenvs.sh

client:		.env
	$(script_dir)/app-test.sh

client-debug:	.env
	$(script_dir)/app-test.sh -h localhost -p 5001

debug:		.update init-db
	$(script_dir)/run.sh flask run --port 5001

drop-db:
	$(script_dir)/run.sh python3 -m app drop-db

init-db:
	$(script_dir)/run.sh python3 -m app init-db

install:	.env .update
	$(script_dir)/install-service.sh

pycode:	.update
	$(script_dir)/run.sh pycodestyle app tests

pylint:	.update
	$(script_dir)/run.sh pylint app tests

pytest:	.update init-db
	$(script_dir)/run.sh pytest tests

realclean:	clean clean-venvs
	@/bin/rm -f .update app/app/*.sqlite

start:		install
	$(script_dir)/start-service.sh

status:
	$(script_dir)/get-service-status.sh

stop:
	$(script_dir)/stop-service.sh

stress:
	$(script_dir)/load-test.sh

uninstall:	stop
	$(script_dir)/uninstall-service.sh

.PHONY: all build clean clean-venvs client client-debug debug drop-db init-db
.PHONY: install pycode pylint pytest init-db realclean start status stop
.PHONY: stress uninstall

.env:			.env-template
	$(script_dir)/configure-env.sh $@ $<

.env-mysql:		.env-template-mysql
	$(script_dir)/configure-env.sh $@ $<

.update:		Pipfile Pipfile.lock
	$(script_dir)/update-virtualenv.sh && touch $@
