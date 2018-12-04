# -*- Mode: Shell-script -*-

# configure-app.sh: configure uWSGI application
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# Application-specific parameters
APP_NAME=stadium-ticket
APP_PORT=5000

configure_common() {
    # Set application directory names from name variable
    APP_DIR=/opt/$APP_NAME
    APP_ETCDIR=/etc/opt/$APP_NAME
    APP_VARDIR=/var/opt/$APP_NAME

    # Set additional parameters from directory variables
    APP_CONFIG=$APP_ETCDIR/app.ini
}

configure_defaults() {
    # Set application group and user identification
    APP_GID=root
    APP_UID=root

    # Set application directory names from name variable
    APP_LOGDIR=/var/opt/$APP_NAME
    APP_RUNDIR=/var/opt/$APP_NAME

    # Set additional parameters from directory variables
    APP_LOGFILE=$APP_LOGDIR/app.log
    APP_PIDFILE=$APP_RUNDIR/pid
    APP_SOCKET=$APP_RUNDIR/sock
    UWSGI_CONF_FILES=
}

configure_opensuse() {
    # Set application group and user identification
    APP_GID=nogroup
    APP_UID=nobody

    # Set uWSGI-specific directories
    UWSGI_ETCDIR=/etc/uwsgi
    UWSGI_LOGDIR=
    UWSGI_RUNDIR=

    # Set application directory names
    APP_LOGDIR=/var/opt/$APP_NAME
    APP_RUNDIR=/var/opt/$APP_NAME

    # Set additional parameters from directory variables
    APP_LOGFILE=$APP_LOGDIR/$APP_NAME.log
    APP_PIDFILE=$APP_RUNDIR/$APP_NAME.pid
    APP_SOCKET=$APP_RUNDIR/$APP_NAME.sock
    UWSGI_CONF_FILES="\
    $UWSGI_ETCDIR/vassals/$APP_NAME.ini \
    "
}

configure_ubuntu() {
    # Set application group and user identification
    APP_GID=www-data
    APP_UID=www-data

    # Set uWSGI-specific directories
    UWSGI_ETCDIR=/etc/uwsgi
    UWSGI_LOGDIR=/var/log/uwsgi/app
    UWSGI_RUNDIR=/var/run/uwsgi/app/$APP_NAME

    # Set application directory names
    APP_LOGDIR=$UWSGI_LOGDIR
    APP_RUNDIR=$UWSGI_RUNDIR

    # Set additional parameters from directory variables
    APP_LOGFILE=$APP_LOGDIR/$APP_NAME.log
    APP_PIDFILE=$APP_RUNDIR/pid
    APP_SOCKET=/run/uwsgi/app/$APP_NAME/socket
    UWSGI_CONF_FILES="\
    $UWSGI_ETCDIR/apps-available/$APP_NAME.ini \
    $UWSGI_ETCDIR/apps-enabled/$APP_NAME.ini \
    "
}

signal_app() {
    # Send restart signal to app
    if [ -n "${APP_PIDFILE:-}" ]; then
	if [ -r $APP_PIDFILE ]; then
	    pid="$(cat $APP_PIDFILE)"

	    if [ -n "$pid" ]; then
		for signal in "$@"; do
		    printf "%s\n" ""
		    printf "Sending SIG%s to process ID: %s\n" $signal $pid

		    if sudo kill -s $signal $pid; then
			printf "SIG%s received by %s\n" $signal $pid
			printf "Waiting %s seconds\n" 5
			sleep 5
		    else
			break
		    fi
		done
	    fi
	elif [ -e $APP_PIDFILE ]; then
	    printf "No permission to read PID file: %s\n" $APP_PIDFILE >&2
	else
	    printf "No such PID file: %s\n" $APP_PIDFILE >&2
	fi
    else
	printf "No PID file to read\n"
    fi
}

tail_logfile() {
    contents=""
    if [ -n "${APP_LOGFILE:-}" ]; then
	if [ -r $APP_LOGFILE ]; then
	    contents=$(tail $APP_LOGFILE)
	elif [ -e $APP_LOGFILE ]; then
	    contents=$(sudo tail $APP_LOGFILE)
	else
	    printf "No such log file: %s\n" $APP_LOGFILE >&2
	fi
    else
	printf "No log file to read\n"
    fi

    if [ -n "$contents" ]; then
	printf "%s\n" ""
	printf "%s\n" "========================================================================"
	printf "%s\n" "Contents of $APP_LOGFILE (or last ten lines):"
	printf "%s\n" "------------------------------------------------------------------------"
	printf "%s\n" "$contents"
	printf "%s\n" "------------------------------------------------------------------------"
    fi
}

distro_name=$(get-os-distro-name)
kernel_name=$(get-os-kernel-name)

configure_common

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (ubuntu)
		configure_ubuntu
		;;
	    (opensuse-*)
		configure_opensuse
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
