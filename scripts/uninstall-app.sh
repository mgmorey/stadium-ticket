#!/bin/sh -eu

# Application-specific parameters
APP_NAME=stadium-ticket

# Set application directory names using name variable
APP_DIR=/opt/$APP_NAME
ETC_DIR=/etc/uwsgi
LOG_DIR=/var/log/uwsgi/app
RUN_DIR=/var/run/uwsgi/app/$APP_NAME
VAR_DIR=/opt/var/$APP_NAME

# Set application filenames using directory variables
APP_CONFIGS="$ETC_DIR/*/$APP_NAME.ini"
APP_LOGFILE=$LOG_DIR/$APP_NAME.log
APP_PIDFILE=$RUN_DIR/pid

# Send interrupt signal to app
for i in 1 2 3 4 5 6; do
    if [ -r $APP_PIDFILE ]; then
	pid=$(cat $APP_PIDFILE)

	if [ -n "$pid" ]; then
	    if sudo kill -s INT $pid; then
		sleep 5
	    else
		break
	    fi
	else
	    break
	fi
    else
	break
    fi
done

# Remove application and configuration
sudo /bin/rm -rf $APP_CONFIGS $APP_DIR $APP_LOGFILE $RUN_DIR $VAR_DIR
