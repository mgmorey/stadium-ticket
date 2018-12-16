#!/bin/sh -eu

# stage-app.sh: stage uWSGI application
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

PYTHON=python3

create_venv() {
    if [ ! -d $virtualenv ]; then
	printf "%s\n" "Creating virtual environment"
	$PYTHON -m venv $virtualenv
    fi

    if [ -d $virtualenv ]; then
	. $script_dir/initialize-virtualenv.sh 
    else
	abort "%s\n" "No virtual environment"
    fi
}

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

if [ $(id -u) -eq 0 ]; then
    abort "%s\n" "This script must be run as a non-privileged user"
fi

script_dir=$(realpath $(dirname $0))
source_dir=$script_dir/..

. "$script_dir/configure-app.sh"

virtualenv=.venv-$APP_NAME
cd "$source_dir"
create_venv
