#!/bin/sh -eu

# start-uwsgi.sh: start uWSGI service
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

start_uwsgi() {
    if [ "$UWSGI_IS_SERVICE" = false ]; then
	return 0
    elif ! is_service_loaded uwsgi; then
	return 0
    elif is_service_running uwsgi; then
	return 0
    fi

    systemctl start uwsgi
}

script_dir=$(get_realpath "$(dirname "$0")")

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/system-parameters.sh"
. "$script_dir/system-functions.sh"

configure_baseline

if [ "$UWSGI_IS_SERVICE" = false ]; then
    exit 0
fi

start_uwsgi

case "$(get_service_status uwsgi)" in
    (exited|running)
	exit 0
	;;
    (*)
	exit 1
	;;
esac
