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

AWK_FMT='NR == 1 || $%s ~ /%s$/ {print $0}\n'

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
	   Code directory: $APP_DIR
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

get_service_process_status() {
    $UWSGI_PS | awk "$(printf "$AWK_FMT" $UWSGI_PS_COL "$UWSGI_BINARY_NAME")"
}

print_service_parameters() {
    get_service_parameters | print_table "SERVICE PARAMETER: VALUE" ${1-}
}

print_service_process_status() {
    get_service_process_status | print_table "" ${1-}
}

print_service_status() {
    print_service_parameters 0
    print_logs $APP_LOGFILE 0
    print_service_process_status
}

script_dir=$(get_realpath "$(dirname "$0")")

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/system-parameters.sh"

configure_system
print_service_status
