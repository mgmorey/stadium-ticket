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

FROM ubuntu:20.04
ARG FTP_PROXY
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ARG ftp_proxy
ARG http_proxy
ARG https_proxy
ARG no_proxy

# Define locale variables
ENV LANG=${LANG:-C.UTF-8} LC_ALL=${LC_ALL:-C.UTF-8}

# Define app name, port, UID and GID variables
ENV APP_NAME=stadium-ticket APP_PORT=5000 APP_UID=www-data APP_GID=www-data

# Define app directory and filename variables
ENV APP_DIR=/opt/$APP_NAME APP_ETCDIR=/etc/opt/$APP_NAME VENV_DIRECTORY=.venv
ENV APP_RUNDIR=/var/run/uwsgi/app/$APP_NAME APP_VARDIR=/var/opt/$APP_NAME
ENV APP_INIFILE=$APP_ETCDIR/app.ini APP_PIDFILE=$APP_RUNDIR/pid
ENV APP_VENVDIR=$APP_DIR/$VENV_DIRECTORY

# Define additional app variables
ENV UWSGI_PLUGIN_NAME=python3 WWW_VARDIR=/var/www

# Update Debian package repository index and install binary packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qqy && apt-get upgrade -qqy && apt-get install \
--no-install-recommends -qqy build-essential libpq-dev python3-dev \
python3-pip python3-setuptools uwsgi uwsgi-plugin-python3 && \
rm -rf /var/lib/apt/lists/*

# Install PyPI packages
RUN python3 -m pip install --no-warn-script-location --upgrade --user pip
RUN python3 -m pip install pipenv

# Create app directories
RUN mkdir -p $APP_DIR $APP_ETCDIR $APP_RUNDIR $APP_VARDIR $WWW_VARDIR

# Copy app files
COPY app/ $APP_DIR/app/
COPY Pipfile app.ini $APP_DIR/
COPY uwsgi.ini $APP_INIFILE

# Copy Docker ENTRYPOINT script
COPY docker-entrypoint.sh /usr/local/bin/

# Grant ownership of app, run and data directories
RUN chown -R $APP_UID:$APP_GID $APP_DIR $APP_RUNDIR $APP_VARDIR $WWW_VARDIR

# Drop privileges and change to app directory
USER $APP_UID:$APP_GID
WORKDIR $APP_DIR

# Install app dependencies
ENV PIPENV_VENV_IN_PROJECT=true
RUN sed -i 's/^\(python_version = \)"\([0-9]\)\.[0-9]*"/\1"\2"/' Pipfile
RUN pipenv install

# Expose port and start app
EXPOSE $APP_PORT
ENTRYPOINT ["docker-entrypoint.sh"]
