#!/bin/sh -eu

# uninstall-app.sh: uninstall uWSGI application
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

abort() {
    printf "$@" >&2
    exit 1
}

abort_extra_arguments() {
    usage "%s: extra arguments -- %s\n" "$0" "$*"
    exit 2
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

get_config_files() (
    printf "%s\n" $APP_CONFIG

    if [ -z "${UWSGI_APPDIRS-}" ]; then
	return 0
    elif [ -z "${UWSGI_ETCDIR-}" ]; then
	return 0
    elif [ ! -d $UWSGI_ETCDIR ]; then
	return 0
    else
	for dir in $UWSGI_APPDIRS; do
	    printf "%s\n" $UWSGI_ETCDIR/$dir/$APP_NAME.ini
	done
    fi
)

get_realpath() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -d "$1" ]
    realpath=$(which realpath)

    if [ -n "$realpath" ]; then
	$realpath "$1"
    elif expr "$1" : '/.*' >/dev/null; then
	printf "%s\n" "$1"
    else
	printf "%s\n" "$PWD/${1#./}"
    fi
)

parse_arguments() {
    purge=false

    while getopts hp opt; do
	case $opt in
	    (p)
		purge=true
		;;
	    (h)
		usage
		exit 0
		;;
	    (\?)
		printf "%s\n" "" >&2
		usage
		exit 2
		;;
	esac
    done

    shift $(($OPTIND - 1))

    if [ $# -gt 0 ]; then
	abort_extra_arguments "$@"
    fi
}

remove_files() {
    if [ $dryrun = true ]; then
	check_permissions "$@"
    else
	printf "Removing %s\n" $(printf "%s\n" "$@" | sort -u)
	/bin/rm -rf "$@"
    fi
}

remove_service() {
    files="$APP_ETCDIR $APP_DIR"

    if [ $purge = true ]; then
	files="$files $APP_VARDIR"

	if [ $APP_RUNDIR != /run -a $APP_RUNDIR != /var/run ]; then
	    files="$files $APP_RUNDIR"
	fi
    fi

    if [ $UWSGI_SOURCE_ONLY = true ]; then
	files="$files $UWSGI_ETCDIR $UWSGI_OPTDIR $UWSGI_LOGFILE"
    fi

    remove_files $(get_config_files) $files
}

stop_service() {
    if [ $dryrun = false ]; then
	case "$kernel_name" in
	    (Linux)
		signal_service $WAIT_SIGNAL INT INT TERM KILL || true
		;;
	    (Darwin)
		control_launch_agent stop
		control_launch_agent unload remove_files
		;;
	esac

	print_logs $APP_LOGFILE && print_footer || true
    fi
}

uninstall_service() {
    parse_arguments "$@"

    for dryrun in true false; do
	stop_service
	remove_service
    done

    printf "Service %s uninstalled successfully\n" $APP_NAME
}

usage() {
    if [ $# -gt 0 ]; then
	printf "$@" >&2
	printf "%s\n" "" >&2
    fi

    cat <<-EOM >&2
	Usage: $0: [-h] [-p]
	EOM
}

script_dir=$(get_realpath "$(dirname "$0")")

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/system-parameters.sh"

configure_system
uninstall_service "$@"
