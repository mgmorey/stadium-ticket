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

PREFIX=/usr/local/opt/uwsgi

OBJECT_DIR=$PREFIX/lib/plugin
PLUGIN=python3_plugin.so

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

. "$script_dir/configure-app.sh"

if uwsgi --version >/dev/null 2>&1; then
    if [ -x $OBJECT_DIR/$PLUGIN ]; then
	if cd $OBJECT_DIR; then
	    uwsgi $APP_CONFIG
	fi
    fi
fi
