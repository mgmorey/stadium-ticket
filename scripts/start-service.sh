#!/bin/sh -eu

# start-service.sh: run application as a service using uWSGI
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

start_service() {
    app_prefix=$APP_DIR/$VENV_FILENAME
    binary=$UWSGI_BINARY_DIR/$UWSGI_BINARY_NAME

    if [ -n "${UWSGI_PLUGIN_DIR-}" ]; then
	plugin=$UWSGI_PLUGIN_DIR/$UWSGI_PLUGIN_NAME
    fi

    if ! $binary --version >/dev/null 2>&1; then
	abort "%s: %s: No such binary file\n" "$0" "$binary"
    fi

    export PATH=$app_prefix/bin:/usr/bin:/bin:/usr/sbin:/sbin
    export PYTHONPATH=$app_prefix/lib

    cd $APP_VARDIR

    if [ ! -e "$binary" ]; then
	abort "%s: %s: No such binary file\n" "$0" "$binary"
    elif [ -n "${UWSGI_PLUGIN_DIR-}" ] && [ ! -d $UWSGI_PLUGIN_DIR ]; then
	abort "%s: %s: No such plugin directory\n" "$0" "$UWSGI_PLUGIN_DIR"
    elif [ -n "${plugin-}" ] && [ ! -e $plugin ]; then
	abort "%s: %s: No such plugin file\n" "$0" "$plugin"
    elif [ ! -d $(dirname $APP_CONFIG) ]; then
	abort "%s: %s: No such configuration directory\n" "$0" "$(dirname $APP_CONFIG)"
    elif [ ! -r $APP_CONFIG ]; then
	abort "%s: %s: No read permission\n" "$0" "$APP_CONFIG"
    elif [ ! -e $APP_CONFIG ]; then
	abort "%s: %s: No such configuration file\n" "$0" "$APP_CONFIG"
    elif signal_service $WAIT_SIGNAL HUP; then
	abort "Service is running as PID %s\n" "$pid"
    else
	$binary${UWSGI_PLUGIN_DIR+ --plugin-dir $UWSGI_PLUGIN_DIR} --ini $APP_CONFIG
    fi
}

script_dir=$(get_realpath "$(dirname "$0")")

. "$script_dir/common-parameters.sh"
. "$script_dir/common-functions.sh"
. "$script_dir/system-parameters.sh"

configure_system
start_service
