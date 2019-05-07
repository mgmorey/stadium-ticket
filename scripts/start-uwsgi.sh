#!/bin/sh -eu

# start-uwsgi.sh: run Flask application using uWSGI
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

get_path() {
    assert [ -d "$1" ]
    command=$(which realpath)

    if [ -n "$command" ]; then
	$command "$1"
    elif expr "$1" : '/.*' >/dev/null; then
	printf "%s\n" "$1"
    else
	printf "%s\n" "$PWD/${1#./}"
    fi
}

script_dir=$(get_path "$(dirname "$0")")

. "$script_dir/common-parameters.sh"
. "$script_dir/configure-app.sh"

binary_dir=$UWSGI_PREFIX/bin
plugin_dir=$UWSGI_PREFIX/lib/plugin

binary=$binary_dir/$UWSGI_BINARY_NAME
plugin=$plugin_dir/$UWSGI_PLUGIN_NAME

if [ -e $APP_PIDFILE ]; then
    pid=$("$script_dir/read-file.sh" $APP_PIDFILE)
    abort "%s: Process already running as PID %s\n" "$0" "$pid"
fi

if $binary --version >/dev/null 2>&1; then
    if [ -x $plugin ]; then
	if cd $plugin_dir; then
	    $binary $APP_CONFIG
	fi
    fi
fi
