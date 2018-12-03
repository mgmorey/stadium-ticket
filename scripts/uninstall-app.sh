#!/bin/sh -eu

# Application-specific parameters
APP_NAME=stadium-ticket

# Set application directory names using name variable
APP_DIR=/opt/$APP_NAME
APP_ETCDIR=/etc/uwsgi
APP_RUNDIR=/opt/var/$APP_NAME
APP_VARDIR=/opt/var/$APP_NAME
UWSGI_ETCDIR=/etc/uwsgi

APP_CONFIG=$APP_ETCDIR/$APP_NAME.ini

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (ubuntu)
		APP_GID=www-data
		APP_UID=www-data

		APP_CONF_AVAIL=$APP_ETCDIR/apps-available/$APP_NAME.ini
		APP_CONF_ENABLED=$APP_ETCDIR/apps-enabled/$APP_NAME.ini
		APP_RUNDIR=/var/run/uwsgi/app/$APP_NAME

		APP_CONF_FILES="$APP_CONFIG $APP_CONF_AVAIL $APP_CONF_ENABLED"
		APP_PIDFILE=$APP_RUNDIR/pid
		APP_SOCKET=$APP_RUNDIR/socket
		;;
	    (opensuse-*)
		APP_GID=nogroup
		APP_UID=nobody

		APP_CONFIG=$APP_ETCDIR/vassals/$APP_NAME.ini

		APP_CONF_FILES="$APP_CONFIG"
		APP_PIDFILE=$APP_RUNDIR/$APP_NAME.pid
		APP_SOCKET=$APP_RUNDIR/$APP_NAME.sock
		;;
	    (*)
		abort "%s: Distro not supported\n" "$distro_name"
		;;
	esac
	;;
    (*)
	abort "%s: Operating system not supported\n" "$kernel_name"
	;;
esac

# Set application filenames using directory variables
APP_CONF_FILES="$APP_ETCDIR/*/$APP_NAME.ini"
APP_LOGFILE=$LOG_DIR/$APP_NAME.log
APP_PIDFILE=$APP_RUNDIR/pid

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
sudo /bin/rm -rf $APP_CONF_FILES $APP_DIR $APP_LOGFILE $APP_VARDIR
