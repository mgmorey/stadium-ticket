# -*- Mode: Shell-script -*-

# configure-app.sh: configure uWSGI application parameters
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

abort() {
    printf "$@" >&2
    exit 1
}

configure_common() {
    # Set application directory names from name variable
    APP_DIR=/opt/$APP_NAME
    APP_ETCDIR=/etc/opt/$APP_NAME
    APP_VARDIR=/var/opt/$APP_NAME

    # Set additional parameters from directory variables
    APP_CONFIG=$APP_ETCDIR/app.ini
}

configure_debian() {
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
    UWSGI_APPDIRS="apps-available apps-enabled"
}

configure_defaults() {
    # Set application group and user identification
    APP_GID=root
    APP_UID=root

    # Set uWSGI-specific directories
    UWSGI_ETCDIR=/etc/uwsgi
    UWSGI_LOGDIR=
    UWSGI_RUNDIR=

    # Set application directory names from name variable
    APP_LOGDIR=$APP_VARDIR
    APP_RUNDIR=$APP_VARDIR

    # Set additional parameters from directory variables
    APP_LOGFILE=$APP_LOGDIR/$APP_NAME.log
    APP_PIDFILE=$APP_RUNDIR/$APP_NAME.pid
    UWSGI_APPDIRS="vassals"
}

configure_opensuse() {
    # Set application group and user identification
    APP_GID=nogroup
    APP_UID=nobody

    # Set uWSGI-specific directories
    UWSGI_ETCDIR=/etc/uwsgi
    UWSGI_LOGDIR=
    UWSGI_RUNDIR=

    # Set application directory names from name variable
    APP_LOGDIR=$APP_VARDIR
    APP_RUNDIR=$APP_VARDIR

    # Set additional parameters from directory variables
    APP_LOGFILE=$APP_LOGDIR/$APP_NAME.log
    APP_PIDFILE=$APP_RUNDIR/$APP_NAME.pid
    UWSGI_APPDIRS="vassals"
}

realpath() {
    if [ -x /usr/bin/realpath ]; then
	/usr/bin/realpath "$@"
    else
	if expr "$1" : '/.*' >/dev/null; then
	    printf "%s\n" "$1"
	else
	    printf "%s\n" "$PWD/${1#./}"
	fi
    fi
}

signal_app() {
    if [ -n "${APP_PIDFILE:-}" ]; then
	if [ -r $APP_PIDFILE ]; then
	    pid="$(cat $APP_PIDFILE)"

	    if [ -n "$pid" ]; then
		for signal in "$@"; do
		    printf "Sending SIG%s to process: %s\n" $signal $pid

		    if kill -s $signal $pid; then
			printf "SIG%s received by process %s\n" $signal $pid
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
	    printf "Waiting %s seconds\n" 5
	    sleep 5
	fi
    else
	printf "No PID file to read\n"
    fi
}

tail_logfile() {
    tmpfile=$(mktemp)

    if [ -n "${APP_LOGFILE:-}" ]; then
	if [ -r $APP_LOGFILE ]; then
	    tail $APP_LOGFILE >$tmpfile
	elif [ -e $APP_LOGFILE ]; then
	    tail $APP_LOGFILE >$tmpfile
	else
	    printf "No such log file: %s\n" $APP_LOGFILE >&2
	fi
    else
	printf "No log file to read\n"
    fi

    if [ -s "$tmpfile" ]; then
	printf "%s\n" ""
	printf "%s\n" "========================================================================"
	printf "%s\n" "Contents of $APP_LOGFILE (or last ten lines):"
	printf "%s\n" "------------------------------------------------------------------------"
	cat $tmpfile
	printf "%s\n" "------------------------------------------------------------------------"
    fi

    /bin/rm -f $tmpfile
}


script_dir=$(realpath $(dirname $0))
distro_name=$($script_dir/get-os-distro-name.sh)
kernel_name=$($script_dir/get-os-kernel-name.sh)

configure_common

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (debian|ubuntu)
		configure_debian
		;;
	    (redhat|centos|fedora)
		configure_defaults
		;;
	    (opensuse-*)
		configure_opensuse
		;;
	    (*)
		abort "%s: Distro not supported\n" "$distro_name"
		;;
	esac
	;;
    (Darwin|FreeBSD|SunOS)
	configure_defaults
	;;
    (*)
	abort "%s: Operating system not supported\n" "$kernel_name"
	;;
esac
