FROM ubuntu:18.04

ENV APP_NAME=stadium-ticket
ENV APP_PORT=5000

# Set Ubuntu GID/UID
ENV APP_GID=www-data
ENV APP_UID=www-data

# Update Debian package repository index and install binary packages
ENV APT_INSTALL="apt-get install -qy --no-install-recommends build-essential \
mariadb-client-10.1 python3 python3-dev python3-pip sqlite3 uwsgi \
uwsgi-plugin-python3"
ENV APT_UPDATE="apt-get update -qy"
ENV DEBIAN_FRONTEND=noninteractive
ENV RETRY='i=0; while [ $i -lt 3 ]; do %s && break; i=$((i + 1)); done\n'
RUN printf "$RETRY" "$APT_UPDATE" "$APT_INSTALL" | sh -x

# Create application directories
ENV APP_DIR=/opt/$APP_NAME
ENV APP_ETCDIR=/opt/etc/$APP_NAME
ENV APP_RUNDIR=/var/run/uwsgi/app/$APP_NAME
ENV APP_VARDIR=/opt/var/$APP_NAME
RUN mkdir -p $APP_DIR $APP_ETCDIR $APP_RUNDIR $APP_VARDIR

# Install application files
COPY app.ini $APP_ETCDIR/
COPY app/ $APP_DIR/app/
COPY .env-docker $APP_DIR/.env
COPY Pipfile* $APP_DIR/

# Change to application directory
WORKDIR $APP_DIR

# Grant application ownership of app, run and data directories
RUN chown -R $APP_UID:$APP_GID $APP_DIR $APP_RUNDIR $APP_VARDIR

# Install dependencies from Pipfile.lock
ENV LANG=${LANG:-C.UTF-8}
ENV LC_ALL=${LC_ALL:-C.UTF-8}
ENV PIPENV_VENV_IN_PROJECT=true
RUN pip3 install pipenv && pipenv sync

# Drop privileges and create database
USER $APP_UID
RUN pipenv run python3 -m app init_db

# Change to data directory, expose port and start app
WORKDIR $APP_VARDIR
EXPOSE $APP_PORT
ENV APP_PIDFILE=$APP_RUNDIR/pid
CMD uwsgi --ini $APP_ETCDIR/app.ini
