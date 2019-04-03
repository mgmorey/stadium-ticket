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

abort() {
    printf "$@" >&2
    exit 1
}

activate_venv() {
    assert [ -n "$1" ] && [ -d $1/bin ] && [ -r $1/bin/activate ]
    printf "%s\n" "Activating virtual environment"
    set +u
    . "$1/bin/activate"
    set -u
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

stage_app() {
    assert [ -n "$1" ]

    if [ ! -d $1 ]; then
	$script_dir/create-virtualenv.sh $1
	populate=true
    else
	populate=false
    fi

    if [ -r $1/bin/activate ]; then
	activate_venv $1

	if [ "$populate" = true ]; then
	    . $script_dir/sync-virtualenv.sh
	fi
    elif [ -d $1 ]; then
	abort "%s\n" "Unable to activate environment"
    else
	abort "%s\n" "No virtual environment"
    fi
}

script_dir=$(realpath "$(dirname "$0")")
stage_app $1
