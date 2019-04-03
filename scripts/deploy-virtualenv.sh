#!/bin/sh -eu

# deploy-virtualenv.sh: deploy Python virtual environment
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
    assert [ -n "$1" ] && [ -d $1/bin ] && [ -r "$1/bin/activate" ]
    printf "%s\n" "Activating virtual environment"
    assert [ -r "$1/bin/activate" ]
    set +u
    . "$1/bin/activate"
    set -u
}

assert() {
    "$@" || abort "%s: Assertion failed: %s\n" "$0" "$*"
}

deploy_venv() {
    assert [ -n "$1" ]

    if [ ! -d $1 ]; then
	sh -eu $script_dir/create-virtualenv.sh $1
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

if [ $# -eq 0 ]; then
    abort "%s\n" "$0: Not enough arguments"
fi

if [ $(id -u) -eq 0 ]; then
    abort "%s\n" "$0: Must be run as a non-privileged user"
fi

script_dir=$(realpath "$(dirname "$0")")
deploy_venv $1
