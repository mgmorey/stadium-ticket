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
    assert [ $# -ge 1 ]
    realpath=$(which realpath)

    if [ -n "$realpath" ]; then
	$realpath "$@"
    else
	for file; do
	    if expr "$file" : '/.*' >/dev/null; then
		printf "%s\n" "$file"
	    else
		printf "%s\n" "$PWD/${file#./}"
	    fi
	done
    fi
)

get_service_parameters() {
    cat <<-EOF
	             Name: $APP_NAME
	             Port: $APP_PORT
	    User/Group ID: $APP_UID/$APP_GID
	    Configuration: $(print_path $APP_CONFIG)
	Program directory: $(print_path $APP_DIR)
	Working directory: $(print_path $APP_VARDIR)
	         Log file: $(print_path $APP_LOGFILE)
	         PID file: $(print_path $APP_PIDFILE)
	   Python version: $(print_parameter $UWSGI_PYTHON_VERSION)
	   Server version: $(print_parameter "$(get_uwsgi_version)")
	      Binary file: $(print_path "$(get_uwsgi_binary_path)")
	      Plugin file: $(print_path "$(get_uwsgi_plugin_path)")
	EOF
}

print_parameter() {
    if [ -n "${1-}" ]; then
	printf "%s\n" "$1"
    else
	printf "%s\n" "<none>"
    fi
}

print_path() {
    if [ -n "${1-}" ] && [ -e $1 ]; then
	printf "%s\n" "$1"
    else
	printf "%s\n" "<none>"
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
print_status $(get_service_status)
