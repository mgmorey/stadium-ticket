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

realpath() {
    if [ -x /usr/bin/realpath ]; then
	/usr/bin/realpath "$@"
    else
	if expr "$1" : '/.*' >/dev/null; then
	    printf "%s\n" "$1"
	else
	    printf "%s\n" "$PWD/${1#./}"
	fi
    fi
}

# Set script directory
script_dir=$(realpath $(dirname $0))

# Set application parameters
. "$script_dir/configure-app.sh"

# Terminate the application
signal_app INT INT TERM KILL

# Tail the log file
tail_log

# Remove application and configuration
files="$UWSGI_ETCDIR/*/$APP_NAME.ini $APP_ETCDIR $APP_DIR $APP_VARDIR"
printf "Removing %s\n" "$files"
/bin/rm -rf $files
