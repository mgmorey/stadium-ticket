# Makefile
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

build:	.env .env-docker .update
	$(script_dir)/run.sh docker-compose up --build

clean:
	$(script_dir)/clean-caches.sh

client:		.env
	$(script_dir)/app-test.sh

client-debug:	.env
	$(script_dir)/app-test.sh -h localhost -p 5001

debug:		.update init-db
	$(script_dir)/run.sh flask run --port 5001

init-db:
	$(script_dir)/run.sh python3 -m app init-db

install:	.env .update
	$(script_dir)/install-app.sh

pycode:	.update
	$(script_dir)/run.sh pycodestyle app tests

pylint:	.update
	$(script_dir)/run.sh pylint app

pytest:	.update init-db
	$(script_dir)/run.sh pytest tests

stress:
	$(script_dir)/load-test.sh

uninstall:
	$(script_dir)/uninstall-app.sh

.PHONY: all build clean client client-debug debug init-db install
.PHONY: pycode pylint pytest init-db stress uninstall

.env:		.env-template
	$(script_dir)/configure-env.sh .env

.env-docker:	.env-template
	$(script_dir)/configure-env.sh .env-docker

.update:	Pipfile Pipfile.lock
	$(script_dir)/update-virtualenv.sh
