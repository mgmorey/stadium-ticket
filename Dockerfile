# Dockerfile
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

FROM ubuntu:18.04

ENV APP_NAME=stadium-ticket
ENV APP_PORT=5000

# Set Ubuntu GID/UID
ENV APP_GID=www-data
ENV APP_UID=www-data

# Set Ubuntu uWSGI plugin
ENV UWSGI_PLUGIN_NAME=python3

# Update Debian package repository index and install binary packages
ENV APT_INSTALL="apt-get install -qy --no-install-recommends build-essential \
mariadb-client-10.1 python3 python3-dev python3-pip sqlite3 uwsgi \
uwsgi-plugin-python3"
ENV APT_UPDATE="apt-get update -qy"
ENV DEBIAN_FRONTEND=noninteractive
ENV RETRY='i=0; while [ $i -lt 3 ]; do %s && break; i=$((i + 1)); done\n'
RUN printf "$RETRY" "$APT_UPDATE" "$APT_INSTALL" | sh -x

# Install PyPI packages
RUN pip3 install pipenv

# Create application directories
ENV APP_DIR=/opt/$APP_NAME
ENV APP_ETCDIR=/opt/etc/$APP_NAME
ENV APP_RUNDIR=/var/run/uwsgi/app/$APP_NAME
ENV APP_VARDIR=/opt/var/$APP_NAME
ENV WWW_VARDIR=/var/www
RUN mkdir -p $APP_DIR $APP_ETCDIR $APP_RUNDIR $APP_VARDIR $WWW_VARDIR

# Install application files
COPY app/ $APP_DIR/app/
COPY Pipfile* $APP_DIR/
COPY app.ini $APP_ETCDIR/

# Grant application ownership of app, run and data directories
RUN chown -R $APP_UID:$APP_GID $APP_DIR $APP_RUNDIR $APP_VARDIR $WWW_VARDIR

# Change to application directory and drop privileges
WORKDIR $APP_DIR
USER $APP_UID

# Install PyPI dependencies
ENV LANG=${LANG:-C.UTF-8}
ENV LC_ALL=${LC_ALL:-C.UTF-8}
ENV PIPENV_VENV_IN_PROJECT=true
RUN pipenv sync
RUN pipenv run python3 -m app init-db

# Change to data directory, expose port and start app
WORKDIR $APP_VARDIR
EXPOSE $APP_PORT
ENV APP_PIDFILE=$APP_RUNDIR/pid
CMD uwsgi --ini $APP_ETCDIR/app.ini
