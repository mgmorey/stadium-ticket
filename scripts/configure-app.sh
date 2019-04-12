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

DOUBLE="======================================================================"
SINGLE="----------------------------------------------------------------------"
KILL_COUNT=20
KILL_INTERVAL=5

abort_insufficient_permissions() {
    cat >&2 <<EOF
$0: You need write permissions for $1
$0: Please retry with root privileges
EOF
    exit 1
}

check_permissions() {
    for file; do
	if [ -e $file -a ! -w $file ]; then
	    abort_insufficient_permissions $file
	elif [ $file != . -a $file != / ]; then
	    check_permissions $(dirname $file)
	fi
    done
}

configure_common() {
    # Set application directory names from name variable
    APP_DIR=/opt/$APP_NAME
    APP_ETCDIR=/etc/opt/$APP_NAME
    APP_VARDIR=/var/opt/$APP_NAME

    # Set additional parameters from directory variables
    APP_CONFIG=$APP_ETCDIR/app.ini
    APP_DATABASE=/tmp/stadium-tickets.sqlite
}

configure_darwin() {
    # Set application group and user identification
    APP_GID=wheel
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
    APP_SOCKET=$APP_RUNDIR/$APP_NAME.sock
    UWSGI_APPDIRS=
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
    APP_SOCKET=$APP_RUNDIR/socket
    UWSGI_APPDIRS="apps-available apps-enabled"
}

configure_freebsd() {
    # Set application group and user identification
    APP_GID=wheel
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
    APP_SOCKET=$APP_RUNDIR/$APP_NAME.sock
    UWSGI_APPDIRS=
}

configure_nt() {
    # Set application group and user identification
    APP_GID="$(id -gn)"
    APP_UID="$(id -un)"

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
    APP_SOCKET=$APP_RUNDIR/$APP_NAME.sock
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
    APP_SOCKET=$APP_RUNDIR/$APP_NAME.sock
    UWSGI_APPDIRS="vassals"
}

configure_sunos() {
    # Set application group and user identification
    APP_GID=sys
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
    APP_SOCKET=$APP_RUNDIR/$APP_NAME.sock
    UWSGI_APPDIRS=
}

remove_database() {
    remove_files "$APP_DATABASE"
}

remove_files() {
    check_permissions "$@"

    if [ "$dryrun" = false ]; then
	printf "Removing %s\n" "$@" | sort -u
	/bin/rm -rf "$@"
    fi
}

print_file_tail() {
    assert [ -n "$1" -a -n "$tmpfile" ]
    tail $1 >$tmpfile

    if [ ! -s "$tmpfile" ]; then
	return
    fi

    printf "%s\n" ""
    printf "%s\n" $DOUBLE
    printf "%s\n" "Contents of $APP_LOGFILE (last 10 lines)"
    printf "%s\n" $SINGLE
    cat $tmpfile
    printf "%s\n" $SINGLE
    printf "%s\n" ""
}

signal_app() {
    pid=$(sh -eu $script_dir/read-file.sh $APP_PIDFILE)
    result=1

    if [ -z "$pid" ]; then
	return $result
    fi

    for signal in "$@"; do
	if [ $result -gt 0 ]; then
	    printf "Sending SIG%s to process (pid: %s)\n" $signal $pid
	fi

	if [ $signal = HUP ]; then
	    if kill -s $signal $pid; then
	        printf "Waiting for process to handle SIG%s\n" "$signal"
		sleep $KILL_INTERVAL
		result=0
	    else
		break
	    fi
	else
	    printf "%s\n" "Waiting for process to die"
	    i=0

	    while kill -s $signal $pid && [ $i -lt $KILL_COUNT ]; do
		sleep 1
		i=$((i + 1))
	    done

	    if [ $i -lt $KILL_COUNT ]; then
		result=0
		break
	    fi
	fi
    done

    return $result
}

tail_log_file() {
    assert [ -n "$APP_LOGFILE" ] && [ -n "$tmpfile" ]

    if [ -r $APP_LOGFILE ]; then
	print_file_tail $APP_LOGFILE
    elif [ -e $APP_LOGFILE ]; then
	printf "No permission to read log file: %s\n" $APP_LOGFILE >&2
    fi
}

distro_name=$(sh -eu $script_dir/get-os-distro-name.sh)
kernel_name=$(sh -eu $script_dir/get-os-kernel-name.sh)
release_name=$(sh -eu $script_dir/get-os-release-name.sh)

configure_common

case "$kernel_name" in
    (Linux)
	case "$distro_name" in
	    (debian)
		case "$release_name" in
		    (10)
			configure_debian
			;;
		    (*)
			abort "%s %s: Release not supported\n" "$distro_name" \
			      "$release_name"
			;;
		esac
		;;
	    (ubuntu)
		configure_debian
		;;
	    (opensuse-*)
		configure_opensuse
		;;
	    (*)
		abort "%s: Distro not supported\n" "$distro_name"
		;;
	esac
	;;
    # (Darwin)
    #	configure_darwin
    #	;;
    # (FreeBSD)
    #	configure_freebsd
    #	;;
    # (SunOS)
    #	configure_sunos
    #	;;
    (*)
	abort "%s: Operating system not supported\n" "$kernel_name"
	;;
esac
