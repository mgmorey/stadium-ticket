#!/bin/sh -eu

# get-service-status.sh: print last few lines of service log file
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

get_service_parameters() {
    cat <<-EOF
	             Name: $APP_NAME
	             Port: $APP_PORT
	          User ID: $APP_UID
	         Group ID: $APP_GID
	    Configuration: $APP_CONFIG
	    App directory: $APP_DIR
	   Data directory: $APP_VARDIR
	         Log file: $APP_LOGFILE
	         PID file: $APP_PIDFILE
	     uWSGI binary: $UWSGI_BINARY_DIR/$UWSGI_BINARY_NAME
EOF

    if [ -n "${UWSGI_PLUGIN_DIR-}" -a -n "${UWSGI_PLUGIN_NAME-}" ]; then
	cat <<-EOF
	     uWSGI plugin: $UWSGI_PLUGIN_DIR/$UWSGI_PLUGIN_NAME
EOF
    fi
}

print_service_parameters() {
    get_service_parameters | print_table "${1-}" "SERVICE PARAMETER: VALUE"
}

print_status() {
    border=1

    for item in parameters log_file processes; do
	eval print_service_$item $border
	border=0
    done

    printf "Service %s is %s\n" "$APP_NAME" "$1"
}

script_dir=$(get_realpath "$(dirname "$0")")

. "$script_dir/common-parameters.sh"
. "$script_dir/system-parameters.sh"
. "$script_dir/system-functions.sh"

configure_system

status=$(get_service_status)
print_status $status
