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

remove_app() {
    remove_files $APP_RUNDIR $APP_DIR $APP_VARDIR $APP_LOGFILE ${DATABASE_FILENAME-}
}

remove_config() {
    remove_files $UWSGI_ETCDIR/*/$APP_NAME.ini $APP_ETCDIR
}

script_dir=$(get_path "$(dirname "$0")")

. "$script_dir/common-functions.sh"
. "$script_dir/configure-app.sh"

tmpfile=$(mktemp)
trap "/bin/rm -f $tmpfile" EXIT INT QUIT TERM

for dryrun in true false; do
    remove_config

    if [ $dryrun = false ]; then
	signal_app INT INT TERM KILL || true
	tail_log_file
    fi

    remove_app
done

printf "App %s stopped and removed successfully\n" $APP_NAME
