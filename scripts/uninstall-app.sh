#!/bin/sh -eu

# uninstall-app.sh: uninstall uWSGI application
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

realpath() {
    assert [ -d "$1" ]

    if [ -x /usr/bin/realpath ]; then
	/usr/bin/realpath "$1"
    else
	if expr "$1" : '/.*' >/dev/null; then
	    printf "%s\n" "$1"
	else
	    printf "%s\n" "$PWD/${1#./}"
	fi
    fi
}

remove_app() {
    remove_files $APP_DIR $APP_VARDIR
}

remove_config() {
    remove_files $UWSGI_ETCDIR/*/$APP_NAME.ini $APP_ETCDIR
}

script_dir=$(realpath "$(dirname "$0")")

. $script_dir/configure-app.sh

for dryrun in true false; do
    remove_config

    if [ $dryrun = false ]; then
	signal_app INT INT TERM KILL
	tail_log
    fi

    remove_app
    remove_database
done
