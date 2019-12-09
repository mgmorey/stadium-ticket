#!/bin/sh -eu

# restart-app.sh: restart application
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

print_status() (
    status=$1

    case $1 in
	(running)
	    if [ $restart_requested = true ]; then
		print_app_log_file 1
		print_app_processes 0
	    fi

	    print_elapsed_time restarted
	    ;;
	(*)
	    exec >&2
	    ;;
    esac

    printf "Service %s is %s\n" "$APP_NAME" "$status"
)

script_dir=$(get_realpath "$(dirname "$0")")

eval $("$script_dir/../../../bin/get-app-configuration" --input app.ini)
. "$script_dir/../../../bin/utility-functions.sh"
. "$script_dir/system-parameters.sh"
. "$script_dir/system-functions.sh"

set_unpriv_environment
configure_all
signal_app_restart

status=$(get_app_status)
print_status $status

case $status in
    (running)
	exit 0
	;;
    (*)
	exit 1
	;;
esac
