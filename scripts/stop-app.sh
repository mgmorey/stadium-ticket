#!/bin/sh -eu

# stop-app.sh: stop application
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

control_app_disable() {
    remove_files $(get_symlinks)
}

control_app_stop() {
    control_app stop
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

print_status() (
    print_app_log_file 1

    status=$1

    case $1 in
	(stopped)
	    :
	    ;;
	(*)
	    exec >&2
	    ;;
    esac

    printf "Service %s is %s\n" "$APP_NAME" "$status"
)

stop_app() {
    for dryrun in true false; do
	control_app_disable

	if [ $dryrun = false ]; then
	    control_app_stop
	fi
    done
}

script_dir=$(get_realpath "$(dirname "$0")")

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/system-parameters.sh"
. "$script_dir/system-functions.sh"

configure_baseline
stop_app

status=$(get_app_status)
print_status $status

case $status in
    (uninstalled|stopped)
	exit 0
	;;
    (*)
	exit 1
	;;
esac
