# -*- Mode: Shell-script -*-

# common-parameters.sh: define commonly used parameters
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

APP_NAME=stadium-ticket
APP_PORT=5000

APP_ENV_VARS="DATABASE_DIALECT DATABASE_HOST DATABASE_PASSWORD DATABASE_PORT \
DATABASE_SCHEMA DATABASE_USER FLASK_APP FLASK_ENV"
APP_INI_VARS="APP_DIR APP_GID APP_LOGFILE APP_NAME APP_PIDFILE APP_PORT \
APP_RUNDIR APP_UID APP_VARDIR UWSGI_PLUGIN_DIR"

PIPENV_OPTS=--three
PYTHONS="python3.6 python3 python"

VENV_FILENAME=.venv
VENV_REQUIREMENTS="requirements-dev.txt requirements.txt"
