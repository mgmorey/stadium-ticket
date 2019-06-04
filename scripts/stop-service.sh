#!/bin/sh -eu

# stop-service.sh: stop application uWSGI service
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
    if [ $stop_requested = true ]; then
	print_service_log_file 1
    fi

    case $1 in
	(stopped)
	    qualified_status=$1

	    if [ $stop_requested = false ]; then
		qualified_status="already $qualified_status"
	    fi

	    printf "Service %s is %s\n" "$APP_NAME" "$qualified_status"
	    ;;
	(*)
	    printf "Service %s is %s\n" "$APP_NAME" "$1" >&2
	    ;;
    esac
}

stop_service() {
    for dryrun in true false; do
	if is_service_running; then
	    request_service_stop
	    stop_requested=true
	else
	    stop_requested=false
	fi

	remove_files $(get_symlinks)
    done
}

script_dir=$(get_realpath "$(dirname "$0")")

. "$script_dir/common-parameters.sh"
. "$script_dir/system-parameters.sh"
. "$script_dir/system-functions.sh"

configure_system
stop_service

status=$(get_service_status)
print_status $status

case $status in
    (uninstalled|stopped)
	exit 0
	;;
    (*)
	exit 1
	;;
esac
