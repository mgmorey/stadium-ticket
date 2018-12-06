FROM ubuntu:18.04

# Application-specific parameters
ENV APP_NAME=stadium-ticket
ENV APP_PORT=5000

# Distro-specific parameters
ENV APP_GID=www-data
ENV APP_UID=www-data
ENV DEBIAN_FRONTEND=noninteractive
ENV RETRY_LOOP="for i in 1 2 3; do %s && break; done\n"

# Update Debian package repository index
ENV APT_UPDATE="apt-get update -qy"
RUN printf "$RETRY_LOOP" "$APT_UPDATE" | sh

# Install dependencies from Debian package repository
ENV APT_INSTALL="apt-get install -qy --no-install-recommends build-essential \
mariadb-client-10.1 python3 python3-dev python3-pip uwsgi uwsgi-plugin-python3"
RUN printf "$RETRY_LOOP" "$APT_INSTALL" | sh

# Create application directories
ENV APP_DIR=/opt/$APP_NAME
ENV APP_ETCDIR=/opt/etc/$APP_NAME
ENV APP_RUNDIR=/var/run/uwsgi/app/$APP_NAME
ENV APP_VARDIR=/opt/var/$APP_NAME
RUN mkdir -p $APP_DIR $APP_ETCDIR $APP_RUNDIR $APP_VARDIR

# Install pipenv package
RUN pip3 install pipenv

# Install application Pipfiles
COPY Pipfile* $APP_DIR/

# Change working directory
WORKDIR $APP_DIR

# Install dependencies in Pipfiles
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PIPENV_VENV_IN_PROJECT=true
RUN pipenv sync

# Copy application files
COPY app/ $APP_DIR/app/
COPY .env $APP_DIR/
COPY app.ini $APP_ETCDIR/

# Make application owner of its own directories
RUN chown -R $APP_UID:$APP_GID $APP_DIR $APP_RUNDIR $APP_VARDIR

# Change working directory
WORKDIR $APP_VARDIR

# Expose application port and start
EXPOSE $APP_PORT
ENV APP_PIDFILE=$APP_RUNDIR/pid
CMD /usr/bin/uwsgi --ini $APP_ETCDIR/app.ini
