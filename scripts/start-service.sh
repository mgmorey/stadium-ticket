#!/bin/sh -eu

# start-service.sh: run application as a service using uWSGI
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

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

create_symlink() {
    assert [ $# -eq 2 ]
    assert [ -n "$2" ]

    if [ $dryrun = true ]; then
	check_permissions "$2"
    else
	assert [ -n "$1" ]
	assert [ -r $1 ]

	if [ $1 != $2 -a ! -e $2 ]; then
	    printf "Creating link %s\n" "$2"
	    mkdir -p $(dirname $2)
	    /bin/ln -s $1 $2
	fi
    fi
}

create_symlinks() (
    assert [ $# -ge 1 ]
    assert [ -n "$1" ]
    file=$1
    shift

    if [ -z "${UWSGI_ETCDIR-}" ]; then
	return 0
    fi

    for dir in "$@"; do
	create_symlink $file $UWSGI_ETCDIR/$dir/$APP_NAME.ini
    done
)

get_realpath() (
    assert [ $# -eq 1 ]
    assert [ -n "$1" ]
    assert [ -d $1 ]
    realpath=$(which realpath)

    if [ -n "$realpath" ]; then
	$realpath "$1"
    elif expr "$1" : '/.*' >/dev/null; then
	printf "%s\n" "$1"
    else
	printf "%s\n" "$PWD/${1#./}"
    fi
)

print_status() (
    status=$1

    case $1 in
	(running)
	    if [ $start_requested = true ]; then
		print_service_log_file 1
		print_service_processes 0
	    fi

	    if [ $elapsed -gt 0 ]; then
		printf "Service %s started in %d seconds\n" "$APP_NAME" "$elapsed"
	    fi

	    if [ $start_requested = false ]; then
		status="already $status"
	    fi
	    ;;
	(*)
	    exec >&2
	    ;;
    esac

    printf "Service %s is %s\n" "$APP_NAME" "$status"
)

run_service() {
    validate_parameters_preinstallation
    validate_parameters_postinstallation

    if [ $dryrun = false ]; then
	command=$(get_uwsgi_binary_path)

	if [ -d "${UWSGI_PLUGIN_DIR-}" ]; then
	    command="$command --plugin-dir $UWSGI_PLUGIN_DIR"
	fi

	$command --ini $APP_CONFIG
    fi
}

request_start() {
    if [ $dryrun = false ]; then
	printf "Starting service %s\n" "$APP_NAME"
    fi

    control_service start $UWSGI_IS_SOURCE_ONLY

    if [ $dryrun = false ]; then
	printf "Waiting for service %s to start\n" "$APP_NAME"
	elapsed=$((elapsed + $(wait_for_service $((WAIT_RESTART - elapsed)))))

	if [ $elapsed -lt $WAIT_DEFAULT ]; then
	    elapsed=$((elapsed + $(wait_for_timeout $((WAIT_DEFAULT - elapsed)))))
	fi
    fi
}

start_service() {
    start_requested=false
    elapsed=0

    if ! is_service_installed; then
	return 0
    elif is_service_running; then
	return 0
    fi

    for dryrun in true false; do
	if [ $UWSGI_RUN_AS_SERVICE = true ]; then
	    start_uwsgi_service
	else
	    run_service
	fi
    done
}

start_uwsgi_service() {
    create_symlinks $APP_CONFIG ${UWSGI_APPDIRS-}
    request_start

    if [ $dryrun = false ]; then
	start_requested=true
    fi
}

script_dir=$(get_realpath "$(dirname "$0")")

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/system-parameters.sh"
. "$script_dir/system-functions.sh"

configure_system
start_service

status=$(get_service_status)
print_status $status

case $status in
    (running)
	exit 0
	;;
    (*)
	exit 1
	;;
esac
