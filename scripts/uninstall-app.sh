#!/bin/sh -eu

# Application-specific parameters
APP_NAME=stadium-ticket

# Set application directory names using name variable
APP_DIR=/opt/$APP_NAME
ETC_DIR=/etc/uwsgi
RUN_DIR=/var/run/uwsgi/app/$APP_NAME
VAR_DIR=/opt/var/$APP_NAME

# Set application filenames using directory variables
APP_AVAILABLE=$ETC_DIR/apps-available/$APP_NAME.ini
APP_ENABLED=$ETC_DIR/apps-enabled/$APP_NAME.ini
APP_PIDFILE=$RUN_DIR/pid

# Send restart signal to app
if [ -r $APP_PIDFILE ]; then
    PID=$(cat $APP_PIDFILE)

    if [ -n "$PID" ]; then
	sudo kill -s TERM $PID
    fi
fi

# Remove application and configuration
sudo /bin/rm -rf $APP_AVAIL $APP_ENABLED $APP_DIR
