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

remove_config() {
    remove_files $APP_ETCDIR $(find $UWSGI_ETCDIR -name $APP_NAME.ini -print)
}

remove_service() {
    remove_files $APP_RUNDIR $APP_DIR $APP_VARDIR $APP_LOGFILE ${DATABASE_FILENAME-}
}

script_dir=$(get_path "$(dirname "$0")")

source_dir=$script_dir/..

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/system-parameters.sh"

configure_system
tmpfile=$(mktemp)
trap "/bin/rm -f $tmpfile" EXIT INT QUIT TERM

for dryrun in true false; do
    if [ $dryrun = false ]; then

	case "$kernel_name" in
	    (Linux)
		signal_service INT INT TERM KILL || true
		;;
	    (Darwin)
		control_launch_agent stop
		control_launch_agent unload
		;;
	esac
	tail_file $APP_LOGFILE
    fi

    remove_service
    remove_config
done

printf "Service %s uninstalled successfully\n" $APP_NAME
