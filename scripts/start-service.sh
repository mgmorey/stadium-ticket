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

print_status() {
    print_service_log_file 1

    case $1 in
	(running)
	    printf "Service %s is %s\n" "$APP_NAME" "$1"
	    ;;
	(*)
	    printf "Service %s is %s\n" "$APP_NAME" "$1" >&2
	    ;;
    esac
}

run_service() {
    validate_parameters_preinstallation
    validate_parameters_postinstallation

    if [ $dryrun = false ]; then
	command=$UWSGI_BINARY_DIR/$UWSGI_BINARY_NAME

	if [ -n "${UWSGI_PLUGIN_DIR-}" ]; then
	    command="$command --plugin-dir $UWSGI_PLUGIN_DIR"
	fi

	$command --ini $APP_CONFIG
    fi
}

request_start() {
    request_service_start
    total_elapsed=0
    printf "Waiting for service %s to start\n" "$APP_NAME"

    wait_period=$((WAIT_RESTART - total_elapsed))
    elapsed=$(wait_for_service $APP_PIDFILE $wait_period)

    total_elapsed=$((total_elapsed + elapsed))

    if [ $total_elapsed -lt $WAIT_DEFAULT ]; then
	elapsed=$(wait_for_timeout $((WAIT_DEFAULT - total_elapsed)))
	total_elapsed=$((total_elapsed + elapsed))
    fi
}

start_service() {
    if ! is_service_installed; then
	return 0
    elif is_service_running; then
	return 0
    fi

    for dryrun in true false; do
	case "$kernel_name" in
	    (FreeBSD)
		run_service
		;;
	    (*)
		if [ $dryrun = false ]; then
		    request_start
		fi
		;;
	esac
    done
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
