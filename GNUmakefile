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

build:	.env .update
	docker build -t stadium-ticket .

clean:
	$(script_dir)/clean-caches.sh

clean-virtualenv:
	$(script_dir)/clean-virtualenv.sh

client:		.env
	$(script_dir)/app-test.sh

client-debug:	.env
	$(script_dir)/app-test.sh -h localhost -p 5001

compose:	.env .env-mysql .update
	docker-compose up --build

debug:		.update init-db
	$(script_dir)/run.sh flask run --port 5001

disable:
	$(script_dir)/disable-service.sh

drop-db:
	$(script_dir)/run.sh python3 -m app drop-db

enable:
	$(script_dir)/enable-service.sh

init-db:
	$(script_dir)/run.sh python3 -m app init-db

install:	.env .update
	$(script_dir)/install-app.sh

pycode:		.update
	$(script_dir)/run.sh pycodestyle app tests

pylint:		.update
	$(script_dir)/run.sh pylint app tests

pytest:		.update init-db
	$(script_dir)/run.sh pytest tests

realclean:	clean clean-virtualenv
	@/bin/rm -f .update app/app/*.sqlite

restart:
	$(script_dir)/restart-app.sh

start:
	$(script_dir)/start-app.sh

status:
	$(script_dir)/get-service-status.sh

stop:
	$(script_dir)/stop-app.sh

stress:
	$(script_dir)/load-test.sh

uninstall:	stop
	$(script_dir)/uninstall-app.sh

.PHONY: all build clean clean-virtualenv client client-debug compose debug
.PHONY: disable drop-db enable init-db install pycode pylint pytest init-db
.PHONY: realclean restart start status stop stress uninstall

.env:		.env-template
	$(script_dir)/configure-env.sh $@ $<

.env-mysql:	.env-template-mysql
	$(script_dir)/configure-env.sh $@ $<

.update:	Pipfile Pipfile.lock
	$(script_dir)/refresh-virtualenv.sh && touch $@
