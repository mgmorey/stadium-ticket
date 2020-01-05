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

# Define app name and port variables
ENV APP_NAME=stadium-ticket
ENV APP_PORT=5000

# Define app GID/UID variables
ENV APP_GID=www-data
ENV APP_UID=www-data

# Define app directory variables
ENV APP_DIR=/opt/$APP_NAME
ENV APP_ETCDIR=/etc/opt/$APP_NAME
ENV APP_RUNDIR=/var/run/uwsgi/app/$APP_NAME
ENV APP_VARDIR=/var/opt/$APP_NAME

# Define app filename variables
ENV APP_INIFILE=$APP_ETCDIR/app.ini
ENV APP_PIDFILE=$APP_RUNDIR/pid

# Define other variables
ENV UWSGI_PLUGIN_NAME=python3
ENV VENV_DIRECTORY=.venv
ENV WWW_VARDIR=/var/www

# Update Debian package repository index and install binary packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qy
RUN apt-get install -qy --no-install-recommends build-essential \
mariadb-client-10.1 python3 python3-dev python3-pip sqlite3 uwsgi \
uwsgi-plugin-python3

# Install PyPI packages
RUN pip3 install pipenv

# Create app directories
RUN mkdir -p $APP_DIR $APP_ETCDIR $APP_RUNDIR $APP_VARDIR $WWW_VARDIR

# Copy app files
COPY Pipfile $APP_DIR/Pipfile
COPY app/ $APP_DIR/app/
COPY app.ini $APP_DIR
COPY uwsgi.sh $APP_DIR

# Copy uWSGI configuration file
COPY uwsgi.ini $APP_INIFILE

# Grant ownership of app, run and data directories
RUN chown -R $APP_UID:$APP_GID $APP_DIR $APP_RUNDIR $APP_VARDIR $WWW_VARDIR

# Drop privileges and change to app directory
USER $APP_UID:$APP_GID
WORKDIR $APP_DIR

# Install app dependencies
ENV LANG=${LANG:-C.UTF-8}
ENV LC_ALL=${LC_ALL:-C.UTF-8}
ENV PIPENV_VENV_IN_PROJECT=true
RUN pipenv install

# Expose port and start app
EXPOSE $APP_PORT
ENTRYPOINT ["./uwsgi.sh"]
CMD ["run", "create-database"]
